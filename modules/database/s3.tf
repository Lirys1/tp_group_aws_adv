
# RANDOM SUFFIX CAR ON EN A BESOIN D'UN


resource "random_id" "bucket" {
  byte_length = 4
}


# S3 BUCKET


resource "aws_s3_bucket" "atlasforge" {

  bucket = "atlasforge-${random_id.bucket.hex}"
}


# LE VERSIONING CAR C'EST IMPORTANT OUI


resource "aws_s3_bucket_versioning" "atlasforge" {

  bucket = aws_s3_bucket.atlasforge.id

  versioning_configuration {

    status = "Enabled"
  }
}


#  LE CHIFFREMENT


resource "aws_s3_bucket_server_side_encryption_configuration" "atlasforge" {

  bucket = aws_s3_bucket.atlasforge.id

  rule {

    apply_server_side_encryption_by_default {

      sse_algorithm = "AES256"
    }
  }
}


# BLOCAGE PUBLIC LE TP PRECENDENT 


resource "aws_s3_bucket_public_access_block" "atlasforge" {

  bucket = aws_s3_bucket.atlasforge.id

  block_public_acls = true

  block_public_policy = true

  ignore_public_acls = true

  restrict_public_buckets = true
}
