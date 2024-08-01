locals {
  model_id = "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
}


resource "aws_iam_role" "query_knowledge_base" {
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

resource "aws_iam_policy" "query_knowledge_base" {
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
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = [aws_bedrockagent_knowledge_base.this.arn]
      },


      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
        ]
        Resource = [local.model_id]
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "query_knowledge_base" {
  role       = aws_iam_role.query_knowledge_base.name
  policy_arn = aws_iam_policy.query_knowledge_base.arn
}

data "archive_file" "query_knowledge_base" {
  type        = "zip"
  source_dir  = var.query_knowledge_base_lambda.dist_dir
  output_path = "${path.root}/.terraform/tmp/lambda-zips/${var.query_knowledge_base_lambda.name}.zip"
}

resource "aws_lambda_function" "query_knowledge_base" {
  function_name = "${var.application}-${var.environment}-${var.query_knowledge_base_lambda.name}"
  filename      = data.archive_file.query_knowledge_base.output_path
  role          = aws_iam_role.query_knowledge_base.arn
  handler       = var.query_knowledge_base_lambda.handler
  source_code_hash = filebase64sha256(data.archive_file.query_knowledge_base.output_path)
  runtime       = "provided.al2023"
  memory_size   = "256"
  architectures = ["arm64"]
  timeout       = 60

  logging_config {
    system_log_level      = "WARN"
    application_log_level = "INFO"
    log_format            = "JSON"
  }

  environment {
    variables = {
      KB_BUCKET = aws_s3_bucket.kb_bucket.id
      KB_ID     = aws_bedrockagent_knowledge_base.this.id
      MODEL_ARN = local.model_id

    }
  }
}

resource "aws_cloudwatch_log_group" "query_knowledge_base_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.query_knowledge_base.function_name}"
  retention_in_days = "3"
}

