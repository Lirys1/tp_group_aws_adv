
# ALB ON VA EN AVOIR BESOIN JUSTE APRES


output "alb_dns_name" {

  value = aws_lb.atlasforge.dns_name
}


# RDS POINT DE LIAISON


output "rds_endpoint" {

  value = aws_db_instance.atlasforge.endpoint
}


# BUCKET


output "bucket_name" {

  value = aws_s3_bucket.atlasforge.bucket
}
