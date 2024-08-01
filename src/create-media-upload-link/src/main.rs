use std::env;
use std::time::Duration;

use aws_config::BehaviorVersion;
use aws_sdk_s3::Client;
use aws_sdk_s3::presigning::PresigningConfig;
use aws_sdk_s3::primitives::ByteStream;
use lambda_http::{Body, Error, Request, Response, run, service_fn, tracing};
use nanoid::nanoid;
use serde_json::json;
use serde_valid::Validate;

use shared::models::MediaMetadata;

async fn create_media_upload_link(
    event: Request,
    s3_client: &aws_sdk_s3::Client,
    media_bucket_name: &str,
) -> Result<Response<Body>, Error> {
    let metadata_request_body = std::str::from_utf8(event.body())?;

    let request: MediaMetadata = match serde_json::from_str(&metadata_request_body) {
        Ok(req) => req,
        Err(err) => {
            return Ok(Response::builder()
                .status(400)
                .header("content-type", "application/json")
                .body(json!({ "error": err.to_string() }).to_string().into())
                .map_err(Box::new)?)
        }
    };

    let validation = request.validate();

    if validation.is_err() {
        let errs = validation.unwrap_err();
        return Ok(Response::builder()
            .status(400)
            .header("content-type", "application/json")
            .body(errs.to_string().into())
            .map_err(Box::new)?);
    }

    let task_id = nanoid!();

    store_staging_media_metadata(
        s3_client,
        media_bucket_name,
        metadata_request_body,
        &task_id,
    )
        .await?;

    let presigned_request_uri =
        generate_presigned_request_uri(s3_client, media_bucket_name, &task_id).await?;

    Ok(Response::builder()
        .status(200)
        .header("content-type", "application/json")
        .body(
            json!({
                "upload_url": presigned_request_uri,
                "task_id":  task_id
            })
                .to_string()
                .into(),
        )
        .map_err(Box::new)?)
}

async fn store_staging_media_metadata(
    s3_client: &Client,
    media_bucket_name: &str,
    metadata_request_body: &str,
    task_id: &str,
) -> Result<(), Error> {
    s3_client
        .put_object()
        .bucket(media_bucket_name)
        .key(format!("media-metadata/{}", task_id))
        .metadata("task_id", task_id)
        .body(ByteStream::from(metadata_request_body.as_bytes().to_vec()))
        .send()
        .await?;
    Ok(())
}

async fn generate_presigned_request_uri(
    s3_client: &Client,
    media_bucket_name: &str,
    task_id: &str,
) -> Result<String, Error> {
    let key = format!("media-uploads/{}", task_id);

    let expires_in = Duration::from_secs(15 * 60);

    let presigned_request = s3_client
        .put_object()
        .bucket(media_bucket_name)
        .key(key)
        .metadata("task_id", task_id)
        .presigned(PresigningConfig::expires_in(expires_in)?)
        .await?;

    let presigned_request_uri = presigned_request.uri();
    Ok(presigned_request_uri.to_string())
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
    let s3_client = aws_sdk_s3::Client::new(&config);

    let media_bucket_name = env::var("MEDIA_BUCKET").expect("MEDIA_BUCKET not set");

    run(service_fn(|event: Request| async {
        create_media_upload_link(event, &s3_client, &media_bucket_name).await
    }))
        .await
}
