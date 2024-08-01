resource "aws_iam_role" "handle_successful_transcription" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "handle_successful_transcription" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "transcribe:GetTranscriptionJob",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = [
          aws_s3_bucket.media_bucket.arn,
          "${aws_s3_bucket.media_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
        ]
        Resource = [
          "${aws_s3_bucket.kb_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = [
          "${aws_s3_bucket.media_bucket.arn}/metadata/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:StartIngestionJob",
        ]
        Resource = [
          aws_bedrockagent_knowledge_base.this.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:AssociateThirdPartyKnowledgeBase",
        ]
        Resource = "*"
        "Condition" = {
          "StringEquals" = {
            "bedrock:ThirdPartyKnowledgeBaseCredentialsSecretArn" : aws_secretsmanager_secret.pinecone_api_key.arn
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "handle_successful_transcription" {
  role       = aws_iam_role.handle_successful_transcription.name
  policy_arn = aws_iam_policy.handle_successful_transcription.arn
}

data "archive_file" "handle_successful_transcription" {
  type        = "zip"
  source_dir  = var.handle_successful_transcription_lambda.dist_dir
  output_path = "${path.root}/.terraform/tmp/lambda-zips/${var.handle_successful_transcription_lambda.name}.zip"
}

resource "aws_lambda_function" "handle_successful_transcription" {
  function_name = "${var.application}-${var.environment}-${var.handle_successful_transcription_lambda.name}"
  filename      = data.archive_file.handle_successful_transcription.output_path
  role          = aws_iam_role.handle_successful_transcription.arn
  handler       = var.handle_successful_transcription_lambda.handler
  source_code_hash = filebase64sha256(data.archive_file.handle_successful_transcription.output_path)
  runtime       = "provided.al2023"
  memory_size   = "128"
  architectures = ["arm64"]

  logging_config {
    system_log_level      = "WARN"
    application_log_level = "INFO"
    log_format            = "JSON"
  }

  environment {
    variables = {
      KB_BUCKET      = aws_s3_bucket.kb_bucket.id
      KB_ID          = aws_bedrockagent_knowledge_base.this.id
      DATA_SOURCE_ID = aws_bedrockagent_data_source.this.data_source_id
      MEDIA_BUCKET   = aws_s3_bucket.media_bucket.id
    }
  }
}

resource "aws_cloudwatch_log_group" "handle_successful_transcription_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.handle_successful_transcription.function_name}"
  retention_in_days = "3"
}

