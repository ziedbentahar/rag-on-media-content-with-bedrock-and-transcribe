resource "aws_lambda_permission" "allow_bucket" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_transcription_job.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.media_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.media_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.start_transcription_job.arn
    events = ["s3:ObjectCreated:*"]
    filter_prefix       = "media-uploads/"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}