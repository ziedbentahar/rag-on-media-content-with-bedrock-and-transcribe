use std::env;

use aws_config::BehaviorVersion;
use aws_sdk_s3::Client;
use aws_sdk_s3::primitives::ByteStream;
use lambda_runtime::{Error, LambdaEvent, run, service_fn, tracing};
use lambda_runtime::tracing::error;
use serde_json::{json, Value};

use shared::models::MediaMetadata;
use transcription_result::TranscriptionResult;

use crate::transcription_success_event::TranscriptionSuccessEvent;

mod transcription_result;

mod transcription_success_event;

async fn handle_transcription_job(
    event: LambdaEvent<Value>,
    transcribe_client: &aws_sdk_transcribe::Client,
    s3_client: &aws_sdk_s3::Client,
    bedrock_agent_client: &aws_sdk_bedrockagent::Client,
    kb_bucket_name: &str,
    kb_id: &str,
    data_source_id: &str,
    media_bucket_name: &str,
) -> Result<(), Error> {
    let e: TranscriptionSuccessEvent = serde_json::from_value(event.payload)?;

    let job_name = e.transcription_job;

    let file_url = transcribe_client
        .get_transcription_job()
        .transcription_job_name(&job_name)
        .send()
        .await?
        .transcription_job
        .ok_or_else(|| Error::from("Transcription Job error"))?
        .transcript
        .ok_or_else(|| Error::from("Transcript error"))?
        .transcript_file_uri
        .ok_or_else(|| Error::from("Transcript file uri error"))?;

    match reqwest::get(file_url).await {
        Ok(resp) => {
            let transcription_result = resp.json::<TranscriptionResult>().await?;

            let transcription_content: Vec<String> = transcription_result
                .results
                .transcripts
                .iter()
                .map(|t| t.transcript.clone())
                .collect();

            let result = transcription_content.join(" ");

            let metadata =
                get_staging_media_metadata(s3_client, media_bucket_name, &job_name).await?;

            store_metadata_content(
                s3_client,
                kb_bucket_name,
                &job_name,
                &result,
                &metadata.to_string(),
            )
                .await?;

            bedrock_agent_client
                .start_ingestion_job()
                .knowledge_base_id(kb_id)
                .data_source_id(data_source_id)
                .send()
                .await?;
        }
        Err(err) => {
            error!({ %err }, "downloading transcription");
            return Err(Box::new(err));
        }
    };

    Ok(())
}

async fn store_metadata_content(
    s3_client: &Client,
    kb_bucket_name: &str,
    job_name: &str,
    transcript: &str,
    metadata: &str,
) -> Result<(), Error> {
    s3_client
        .put_object()
        .bucket(kb_bucket_name)
        .content_type("application/json")
        .key(format!("{}/{}.metadata.json", "transcripts", &job_name))
        .body(ByteStream::from(metadata.as_bytes().to_vec()))
        .send()
        .await?;

    s3_client
        .put_object()
        .bucket(kb_bucket_name)
        .content_type("text/plain")
        .key(format!("{}/{}", "transcripts", &job_name))
        .body(ByteStream::from(transcript.as_bytes().to_vec()))
        .send()
        .await?;
    Ok(())
}

async fn get_staging_media_metadata(
    s3_client: &Client,
    media_bucket_name: &str,
    task_id: &str,
) -> Result<Value, Error> {
    let staging_metadata_object = s3_client
        .get_object()
        .bucket(media_bucket_name)
        .key(format!("media-metadata/{}", &task_id))
        .send()
        .await?;

    let data = staging_metadata_object.body.collect().await?;
    let content = String::from_utf8(data.into_bytes().to_vec())?;
    let data: MediaMetadata = serde_json::from_str(&content)?;

    let metadata = json!({
        "metadataAttributes" : {
            "topic" : data.topic,
            "source_url": data.source_url
        }
    });
    Ok(metadata)
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
    let transcribe_client = aws_sdk_transcribe::Client::new(&config);
    let bedrock_agent_client = aws_sdk_bedrockagent::Client::new(&config);
    let s3_client = aws_sdk_s3::Client::new(&config);

    let kb_bucket_name = env::var("KB_BUCKET").expect("KB_BUCKET not set");
    let media_buket_name = env::var("MEDIA_BUCKET").expect("MEDIA_BUCKET not set");
    let kb_id = env::var("KB_ID").expect("KB_ID not set");
    let data_source_id = env::var("DATA_SOURCE_ID").expect("DATA_SOURCE_ID not set");

    run(service_fn(|event: LambdaEvent<Value>| async {
        handle_transcription_job(
            event,
            &transcribe_client,
            &s3_client,
            &bedrock_agent_client,
            &kb_bucket_name,
            &kb_id,
            &data_source_id,
            &media_buket_name,
        )
            .await
    }))
        .await
}
