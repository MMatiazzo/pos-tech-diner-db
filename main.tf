provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "eks_state" {
  backend = "s3"

  config = {
    bucket = "bucket-name"
    key    = "path/to/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_security_group" "sg-rds" {
  name        = "SG-pos-tech-diner-rds"
  description = "pos-tech-diner"
  vpc_id      = data.terraform_remote_state.eks_state.outputs["aws_vpc_main_id"]

  ingress {
    description = "VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "aws_subnet_groups_rds"
  subnet_ids = [
    data.terraform_remote_state.eks_state.outputs["aws_subnet_private_us_east_1a_id"],
    data.terraform_remote_state.eks_state.outputs["aws_subnet_private_us_east_1b_id"]
  ]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "rds" {
  db_name        = "postechdinerdb"
  engine         = "postgres"
  engine_version = "13.10"
  identifier     = "rds-pos-tech-diner"
  # manage_master_user_password  = true 
  username                     = "change"
  password                     = "change"
  instance_class               = "db.t3.micro"
  storage_type                 = "gp2"
  allocated_storage            = "20"
  max_allocated_storage        = "30"
  multi_az                     = false
  vpc_security_group_ids       = [aws_security_group.sg-rds.id]
  db_subnet_group_name         = aws_db_subnet_group.default.name
  apply_immediately            = true
  skip_final_snapshot          = true
  publicly_accessible          = false
  deletion_protection          = true
  performance_insights_enabled = true
  backup_retention_period      = 1
  backup_window                = "00:00-00:30"
  copy_tags_to_snapshot        = true
  delete_automated_backups     = true
}
