resource "aws_secretsmanager_secret" "pinecone_api_key" {}

#Store the secret value
resource "aws_secretsmanager_secret_version" "example_secret_value" {
  secret_id = aws_secretsmanager_secret.pinecone_api_key.id
  secret_string = jsonencode({
    apiKey = var.pinecone_api_key
  })
}