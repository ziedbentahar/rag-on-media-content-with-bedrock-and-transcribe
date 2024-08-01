use std::collections::HashSet;
use std::env;

use aws_config::BehaviorVersion;
use aws_sdk_bedrockagentruntime::operation::retrieve_and_generate::RetrieveAndGenerateOutput;
use aws_sdk_bedrockagentruntime::types::{
    FilterAttribute, KnowledgeBaseRetrievalConfiguration,
    KnowledgeBaseRetrieveAndGenerateConfiguration, KnowledgeBaseVectorSearchConfiguration,
    RetrievalFilter, RetrieveAndGenerateConfiguration, RetrieveAndGenerateInput, RetrieveAndGenerateType,
};
use lambda_http::{Body, Error, Request, Response, run, service_fn, tracing};
use serde_valid::json::json;
use serde_valid::Validate;

use crate::query::Query;

mod query;

async fn query_knowledge_base(
    event: Request,
    bedrock_agent_runtime_client: &aws_sdk_bedrockagentruntime::Client,
    knowledge_base_id: &str,
    model_arn: &str,
) -> Result<Response<Body>, Error> {
    let query_body = std::str::from_utf8(event.body())?;

    let query: Query = match serde_json::from_str(&query_body) {
        Ok(req) => req,
        Err(err) => {
            return Ok(Response::builder()
                .status(400)
                .header("content-type", "application/json")
                .body(json!({ "error": err.to_string() }).to_string().into())
                .map_err(Box::new)?)
        }
    };

    let validation = query.validate();

    if validation.is_err() {
        let errs = validation.unwrap_err();
        return Ok(Response::builder()
            .status(400)
            .header("content-type", "application/json")
            .body(errs.to_string().into())
            .map_err(Box::new)?);
    }

    let configuration =
        build_retrieve_and_generate_configuration(knowledge_base_id, model_arn, &query)?;

    let input = RetrieveAndGenerateInput::builder()
        .text(query.input)
        .build()?;

    let result = bedrock_agent_runtime_client
        .retrieve_and_generate()
        .retrieve_and_generate_configuration(configuration)
        .input(input)
        .send()
        .await?;

    if result.output.is_none() {
        return Ok(Response::builder()
            .status(404)
            .header("content-type", "application/json")
            .body("Not found".into())
            .map_err(Box::new)?);
    }

    let (output_text, sources) = unwrap_result(result);

    let resp = Response::builder()
        .status(200)
        .header("content-type", "application/json")
        .body(
            json!({
                "output": output_text,
                "sources": sources
            })
                .to_string()
                .into(),
        )
        .map_err(Box::new)?;

    Ok(resp)
}

fn unwrap_result(rng_output: RetrieveAndGenerateOutput) -> (std::string::String, HashSet<std::string::String>) {
    let output_text = rng_output.output.unwrap().text;

    let sources: HashSet<_> = rng_output
        .citations
        .unwrap_or_default()
        .into_iter()
        .flat_map(|citation| citation.retrieved_references.unwrap_or_default())
        .filter_map(|reference| {
            reference
                .metadata
                .as_ref()
                .and_then(|metadata| metadata.get("source_url"))
                .and_then(|url| url.as_string().map(|url_str| url_str.to_string()))
        })
        .collect();

    (output_text, sources)
}

fn build_retrieve_and_generate_configuration(
    knowledge_base_id: &str,
    model_arn: &str,
    query: &Query,
) -> Result<RetrieveAndGenerateConfiguration, Error> {
    let q = query.clone();

    let filter = RetrievalFilter::Equals(
        FilterAttribute::builder()
            .key("topic")
            .value(q.topic.into())
            .build()?,
    );

    // Create the vector search configuration
    let vector_search_config = KnowledgeBaseVectorSearchConfiguration::builder()
        .filter(filter)
        .build();

    let retrieval_config = KnowledgeBaseRetrievalConfiguration::builder()
        .vector_search_configuration(vector_search_config)
        .build();

    let rng_config = KnowledgeBaseRetrieveAndGenerateConfiguration::builder()
        .retrieval_configuration(retrieval_config)
        .knowledge_base_id(knowledge_base_id)
        .model_arn(model_arn)
        .build()
        .map_err(Box::new)?;

    let configuration = RetrieveAndGenerateConfiguration::builder()
        .r#type(RetrieveAndGenerateType::KnowledgeBase)
        .knowledge_base_configuration(rng_config)
        .build()
        .map_err(Box::new)?;

    Ok(configuration)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt()
        .json()
        .with_max_level(tracing::Level::INFO)
        .with_current_span(false)
        .with_ansi(false)
        .without_time()
        .with_target(false)
        .init();

    let config = aws_config::load_defaults(BehaviorVersion::latest()).await;

    let bedrock_agent_runtime_client = aws_sdk_bedrockagentruntime::Client::new(&config);

    let knowledge_base_id = env::var("KB_ID").expect("KB_ID not set");
    let model_arn = env::var("MODEL_ARN").expect("MODEL_ARN not set");

    run(service_fn(|event: Request| async {
        query_knowledge_base(
            event,
            &bedrock_agent_runtime_client,
            &knowledge_base_id,
            &model_arn,
        )
            .await
    }))
        .await
}
