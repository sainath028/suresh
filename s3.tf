resource "aws_s3_bucket" "code-pipeline" {
  bucket = "my-tf-test-bucke-rts"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.code-pipeline.id
  acl    = "private"
}

resource "aws_s3_bucket" "website" {
  bucket = "s3-website-test.hashicorp.com.srt"
  force_destroy = true
  policy = file("policy.json")
}

resource "aws_s3_bucket_website_configuration" "web_config" {
  bucket = aws_s3_bucket.website.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

resource "aws_s3_bucket_acl" "web_bucket_acl" {
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}