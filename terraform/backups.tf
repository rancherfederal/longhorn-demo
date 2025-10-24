# bucket to store backups
resource "aws_s3_bucket" "backups" {
  bucket = "${var.resource_name}-backups"
  force_destroy = true
  object_lock_enabled = false # longhorn itself handles this
}

resource "aws_s3_bucket_ownership_controls" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

# IAM user for bucket reads/writes
data "aws_iam_policy_document" "backups" {
  statement {
    effect = "Allow"
    resources = [
      aws_s3_bucket.backups.arn,
      "${aws_s3_bucket.backups.arn}/*"
    ]
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
  }
}

resource "aws_iam_policy" "backups" {
  name = "${var.resource_name}-backups"
  description = "Allow IAM user to perform Longhorn Volume backups"
  policy = data.aws_iam_policy_document.backups.json
}

resource "aws_iam_user" "backups" {
  name = "${var.resource_name}-backups"
}

resource "aws_iam_user_policy_attachment" "backups" {
  user = aws_iam_user.backups.name
  policy_arn = aws_iam_policy.backups.arn
}

resource "aws_iam_access_key" "backups" {
  user = aws_iam_user.backups.name  
}
