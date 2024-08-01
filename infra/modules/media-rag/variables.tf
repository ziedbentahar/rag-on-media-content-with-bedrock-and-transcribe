variable "start_transcription_job_lambda" {
  type = object({
    dist_dir = string
    name     = string
    handler  = string
  })
}


variable "handle_successful_transcription_lambda" {
  type = object({
    dist_dir = string
    name     = string
    handler  = string
  })
}

variable "create_media_upload_link_lambda" {
  type = object({
    dist_dir = string
    name     = string
    handler  = string
  })
}

variable "query_knowledge_base_lambda" {
  type = object({
    dist_dir = string
    name     = string
    handler  = string
  })
}

variable "application" {
  type = string
}

variable "environment" {
  type = string
}

variable "pinecone_api_key" {
  type = string
}