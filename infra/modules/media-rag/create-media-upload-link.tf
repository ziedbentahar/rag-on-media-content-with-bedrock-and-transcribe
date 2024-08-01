resource "aws_iam_role" "create_media_upload_link" {
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

resource "aws_iam_policy" "create_media_upload_link" {
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
          "s3:PutObject",
        ]
        Resource = "${aws_s3_bucket.media_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "create_media_upload_link" {
  role       = aws_iam_role.create_media_upload_link.name
  policy_arn = aws_iam_policy.create_media_upload_link.arn
}

data "archive_file" "create_media_upload_link" {
  type        = "zip"
  source_dir  = var.create_media_upload_link_lambda.dist_dir
  output_path = "${path.root}/.terraform/tmp/lambda-zips/${var.create_media_upload_link_lambda.name}.zip"
}

resource "aws_lambda_function" "create_media_upload_link" {
  function_name = "${var.application}-${var.environment}-${var.create_media_upload_link_lambda.name}"
  filename      = data.archive_file.create_media_upload_link.output_path
  role          = aws_iam_role.create_media_upload_link.arn
  handler       = var.create_media_upload_link_lambda.handler
  source_code_hash = filebase64sha256(data.archive_file.create_media_upload_link.output_path)
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
      MEDIA_BUCKET = aws_s3_bucket.media_bucket.id
    }
  }
}

resource "aws_cloudwatch_log_group" "create_media_upload_link_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.create_media_upload_link.function_name}"
  retention_in_days = "3"
}

