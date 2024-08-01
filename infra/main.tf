module "media-rag" {
  source = "./modules/media-rag"

  application = var.application
  environment = var.environment

  pinecone_api_key = var.pinecone_api_key

  start_transcription_job_lambda = {
    dist_dir = "../src/target/lambda/start-transcription-job"
    name     = "start-transcription-job"
    handler  = "bootstrap"
  }

  handle_successful_transcription_lambda = {
    dist_dir = "../src/target/lambda/handle-successful-transcription"
    name     = "handle-successful-transcription"
    handler  = "bootstrap"
  }

  create_media_upload_link_lambda = {
    dist_dir = "../src/target/lambda/create-media-upload-link"
    name     = "create-media-upload-link"
    handler  = "bootstrap"
  }

  query_knowledge_base_lambda = {
    dist_dir = "../src/target/lambda/query-knowledge-base"
    name     = "query-knowledge-base"
    handler  = "bootstrap"
  }

}