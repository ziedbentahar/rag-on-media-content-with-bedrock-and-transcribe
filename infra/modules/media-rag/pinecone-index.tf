resource "pinecone_index" "media_transcriptions" {
  name      = "${var.application}${var.environment}-media-transcriptions"
  dimension = 1024
  metric    = "cosine"
  spec = {
    serverless = {
      cloud  = "aws"
      region = "us-east-1"
    }
  }
}

