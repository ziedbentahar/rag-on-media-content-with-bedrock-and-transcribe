resource "aws_s3_bucket" "kb_bucket" {
  bucket = "${var.application}-${var.environment}-kb-${random_pet.this.id}"
}
