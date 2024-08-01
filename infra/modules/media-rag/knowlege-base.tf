resource "aws_iam_role" "kb_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "kb_policy" {
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
          "secretsmanager:GetSecretValue",
        ]
        Resource = aws_secretsmanager_secret.pinecone_api_key.arn
      },
      {
        "Action" : [
          "bedrock:InvokeModel"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:bedrock:${data.aws_region.current.id}::foundation-model/amazon.titan-embed-text-v2:0"
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
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.kb_bucket.arn,
          "${aws_s3_bucket.kb_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kb_role_attachment" {
  role       = aws_iam_role.kb_role.name
  policy_arn = aws_iam_policy.kb_policy.arn
}

resource "aws_bedrockagent_knowledge_base" "this" {

  name     = "${var.application}-${var.environment}-media-kb"
  role_arn = aws_iam_role.kb_role.arn

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${data.aws_region.current.id}::foundation-model/amazon.titan-embed-text-v2:0"
    }
    type = "VECTOR"
  }

  storage_configuration {
    type = "PINECONE"
    pinecone_configuration {
      connection_string      = "https://${pinecone_index.media_transcriptions.host}"
      credentials_secret_arn = aws_secretsmanager_secret.pinecone_api_key.arn

      field_mapping {
        metadata_field = "metadata"
        text_field     = "text"
      }
    }
  }

  depends_on = [
    pinecone_index.media_transcriptions,
    aws_secretsmanager_secret.pinecone_api_key
  ]
}

resource "aws_bedrockagent_data_source" "this" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "kb_datasource"

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }

  data_source_configuration {

    type = "S3"
    s3_configuration {

      bucket_arn = aws_s3_bucket.kb_bucket.arn
      inclusion_prefixes = ["transcripts"]
    }
  }
}
