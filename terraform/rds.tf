resource "aws_security_group" "rds" {
  vpc_id = module.vpc.id

  ingress {
    protocol  = "tcp"
    from_port = "0"
    to_port   = "0"
    security_groups = [
      aws_security_group.main.id
    ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_instance" "main" {
  identifier                = "cci"
  engine                    = "postgres"
  engine_version            = "13.10"
  instance_class            = "db.t3.micro"
  allocated_storage         = 4
  db_name                   = "cci"
  username                  = "admin"
  password                  = "cci_admin"
  db_subnet_group_name      = module.vpc.database_subnet_group_name
  vpc_security_group_ids    = [aws_security_group.rds.id]
  skip_final_snapshot       = false
  final_snapshot_identifier = "cci-snapshot"
  publicly_accessible       = false
  deletion_protection       = false
  storage_encrypted         = true
  copy_tags_to_snapshot     = true
  backup_retention_period   = 1
  backup_window             = "00:00-00:30"
  apply_immediately         = true
}

# resource "aws_db_instance" "read_only_replica" {
#   replicate_source_db        = aws_db_instance.main.id
#   replica_mode               = "mounted"
#   auto_minor_version_upgrade = false
#   backup_retention_period    = 1
#   identifier                 = "cci-replica"
#   instance_class             = "db.t3.micro"
#   db_subnet_group_name       = module.vpc.database_subnet_group_name
#   vpc_security_group_ids     = [aws_security_group.rds.id]
#   multi_az                   = true
# }

