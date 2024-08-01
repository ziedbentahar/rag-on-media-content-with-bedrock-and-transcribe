resource "aws_iam_role" "start_transcription_job" {
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

resource "aws_iam_policy" "start_transcription_job" {
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
          "transcribe:TagResource",
          "transcribe:StartTranscriptionJob",
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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "start_transcription_job" {
  role       = aws_iam_role.start_transcription_job.name
  policy_arn = aws_iam_policy.start_transcription_job.arn
}

data "archive_file" "start_transcription_job" {
  type        = "zip"
  source_dir  = var.start_transcription_job_lambda.dist_dir
  output_path = "${path.root}/.terraform/tmp/lambda-zips/${var.start_transcription_job_lambda.name}.zip"
}

resource "aws_lambda_function" "start_transcription_job" {
  function_name = "${var.application}-${var.environment}-${var.start_transcription_job_lambda.name}"
  filename      = data.archive_file.start_transcription_job.output_path
  role          = aws_iam_role.start_transcription_job.arn
  handler       = var.start_transcription_job_lambda.handler
  source_code_hash = filebase64sha256(data.archive_file.start_transcription_job.output_path)
  runtime       = "provided.al2023"
  memory_size   = "128"
  architectures = ["arm64"]

  logging_config {
    system_log_level      = "WARN"
    application_log_level = "ERROR"
    log_format            = "JSON"
  }
}

resource "aws_cloudwatch_log_group" "start_transcription_job_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.start_transcription_job.function_name}"
  retention_in_days = "3"
}

