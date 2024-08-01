use aws_lambda_events::event::s3::S3Event;
use aws_sdk_transcribe::config::BehaviorVersion;
use aws_sdk_transcribe::types::{Media, Settings, Tag};
use lambda_runtime::{Error, LambdaEvent, run, service_fn, tracing};

async fn start_transcription_job(
    event: LambdaEvent<S3Event>,
    transcribe_client: &aws_sdk_transcribe::Client,
) -> Result<(), Error> {
    for record in event.payload.records {
        let object_key = record.s3.object.key.unwrap();

        let task_id = object_key.split("/").last().unwrap();

        let output = transcribe_client
            .start_transcription_job()
            .transcription_job_name(task_id)
            .settings(
                Settings::builder()
                    .show_speaker_labels(true)
                    .max_speaker_labels(5)
                    .build(),
            )
            .identify_language(true)
            .media(
                Media::builder()
                    .media_file_uri(format!(
                        "s3://{}/{}",
                        record.s3.bucket.name.unwrap(),
                        &object_key
                    ))
                    .build(),
            )
            .tags(
                Tag::builder()
                    .key("task_id")
                    .value(task_id)
                    .build()
                    .unwrap(),
            )
            .send()
            .await;

        if let Err(err) = output {
            return Err(Box::new(err));
        }
    }

    Ok(())
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

    run(service_fn(|event: LambdaEvent<S3Event>| async {
        start_transcription_job(event, &transcribe_client).await
    }))
        .await
}
