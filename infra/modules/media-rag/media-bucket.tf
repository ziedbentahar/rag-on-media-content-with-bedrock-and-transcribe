resource "aws_s3_bucket" "media_bucket" {
  bucket = "${var.application}-${var.environment}-medias-${random_pet.this.id}"
}

resource "aws_s3_bucket_policy" "allow_transcribe" {
  bucket = aws_s3_bucket.media_bucket.id
  policy = data.aws_iam_policy_document.media_bucket.json
}


data "aws_iam_policy_document" "media_bucket" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["transcribe.amazonaws.com"]
    }
    resources = [
      aws_s3_bucket.media_bucket.arn,
      "${aws_s3_bucket.media_bucket.arn}/*"
    ]
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
  }
}


