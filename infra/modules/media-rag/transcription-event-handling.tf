resource "aws_sqs_queue" "transcription_dlq" {
  name = "${var.application}-${var.environment}-transcription-dlq"
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handle_successful_transcription.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.transcription_success.arn
}

resource "aws_iam_role" "eb_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "eb_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
        ]
        Resource = [aws_lambda_function.handle_successful_transcription.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
        ]
        Resource = [aws_sqs_queue.transcription_dlq.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eb_role_attachment" {
  role       = aws_iam_role.eb_role.name
  policy_arn = aws_iam_policy.eb_policy.arn
}

resource "aws_cloudwatch_event_rule" "transcription_success" {
  name = "transcription-success"

  event_pattern = jsonencode({
    "source" : ["aws.transcribe"], "detail" : {
      "TranscriptionJobStatus" : ["COMPLETED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "transcription_success" {
  rule      = aws_cloudwatch_event_rule.transcription_success.name
  target_id = "handleTranscriptionSuccess"
  arn       = aws_lambda_function.handle_successful_transcription.arn
  dead_letter_config {
    arn = aws_sqs_queue.transcription_dlq.arn
  }

  retry_policy {
    maximum_event_age_in_seconds = 60 * 60
    maximum_retry_attempts       = 10
  }

  input_transformer {
    input_paths = {
      transcriptionJob : "$.detail.TranscriptionJobName"
    }

    input_template = <<TEMPLATE
{
  "transcriptionJob":"<transcriptionJob>"
}
TEMPLATE
  }
}


resource "aws_cloudwatch_event_rule" "transcription_failure" {
  name = "transcription-failure"

  event_pattern = jsonencode({
    "source" : ["aws.transcribe"], "detail" : {
      "TranscriptionJobStatus" : ["FAILED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "dlq" {
  rule      = aws_cloudwatch_event_rule.transcription_failure.name
  target_id = "transcriptionErrorsDlq"
  arn       = aws_sqs_queue.transcription_dlq.arn
}

resource "aws_iam_role" "kb_sync" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.transcription_dlq.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.transcription_dlq.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : aws_cloudwatch_event_rule.transcription_failure.arn
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "kb_sync" {
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
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",

        ]
        Resource = [aws_lambda_function.handle_successful_transcription.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kb_sync" {
  role       = aws_iam_role.kb_sync.name
  policy_arn = aws_iam_policy.kb_sync.arn
}



