
# DB SUBNET GROUP


resource "aws_db_subnet_group" "atlasforge" {

  name = "atlasforge-db-subnets"

  subnet_ids = [
    aws_subnet.db_a.id,
    aws_subnet.db_b.id
  ]
}


# RDS POSTGRESQL


resource "aws_db_instance" "atlasforge" {

  identifier = "atlasforge-rds"

  engine = "postgres"

  engine_version = "15"

  instance_class = "db.t3.micro"

  allocated_storage = 20

  username = "postgres"

  password = var.db_password

  db_name = "atlasbook"

  db_subnet_group_name = aws_db_subnet_group.atlasforge.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  skip_final_snapshot = true

  multi_az = false
}
