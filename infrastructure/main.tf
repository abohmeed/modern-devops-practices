locals {
  cidr             = "10.0.0.0/16"
  azs              = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  db_name          = "moderndevopsdb"
  ubuntu_ami       = "ami-015423a987dafce81"
  db_username      = "dbadmin"
}
module "vpc" {
  # source                = "git::ssh://git@gitlab.com/abohmeed/terraform-modules.git//vpc?ref=main"
  source                       = "terraform-aws-modules/vpc/aws"
  version                      = "3.19.0"
  cidr                         = local.cidr
  azs                          = local.azs
  private_subnets              = local.private_subnets
  public_subnets               = local.public_subnets
  enable_nat_gateway           = true
  single_nat_gateway           = true
  one_nat_gateway_per_az       = false
  create_database_subnet_group = true
  database_subnet_group_name   = "db"
  database_subnets             = local.database_subnets
}
# Security groups
module "auth_service_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "auth-service"
  description = "Security group for auth-service"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "auth-service ports"
      cidr_blocks = local.cidr
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Allow all outbound connections"
      cidr_blocks = local.cidr
    },
  ]
}
module "ui_service_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "ui-service"
  description = "Security group for ui-service"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "ui-service ports"
      cidr_blocks = local.cidr
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Allow all outbound connections"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
module "weather_service_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "weather-service"
  description = "Security group for weather-service"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 5000
      to_port     = 5000
      protocol    = "tcp"
      description = "weather-service ports"
      cidr_blocks = local.cidr
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Allow all outbound connections"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
module "ssh_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "ssh-service"
  description = "Security group for SSH access"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = " SSH service ports"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Allow all outbound connections"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
module "db_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "db"
  description = "Security group for the RDS instance"
  vpc_id      = module.vpc.vpc_id
  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = local.cidr
    },
  ]
}
# EC2 instances
resource "aws_key_pair" "devops" {
  key_name   = "devops-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7e8uiDcqsG3HcQMwHZ+BQK5Eouvrd2XQW78yDbxvg/pNqLdoeEr+DW/gR8T0ym1kcYGnxLf4mSsTNhzyGfrmeMk0c0lGsXunbpvne96PWkr/5NMRoj9qswoNtfK672QiNucDLCue63tgvou9/hlGLKU8uH29ZSd4QwsbgEtvOigF023lJsOBWSVAng/fFE3wZkhZB3Us29T/DHsTol2h6Zs2yzkM+u/fp8g9Hcm7DQdsbMYQ+R9O8AsVLfHzeqX/MqDGGlqub7n/TZipz7x7wf4FNRnPHWaMKs8PXM2DyVswXTucMZATr8ClFBbSHKU+4vgaolUbBbhIm+FP4CW0t+4PgNwyISyBoBv/b4SGUzaRzbLQEdsVXp8A/srNn5zecswYzGR9icPkNXINNJemW2L7OPJLX2SUBpMwNU4JkiuYdp9GR+n9XqH5LVlOLaW/cT7h4aKKmy4UHRbfL+t89moe05Izz180AIZDVpLdWvWptW2pkc1x852BP3dJnNKU="
}
module "auth_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  name = "auth-instance"

  ami                    = local.ubuntu_ami
  instance_type          = "t3.micro"
  key_name               = "devops-key"
  monitoring             = true
  vpc_security_group_ids = [module.auth_service_sg.security_group_id, module.ssh_sg.security_group_id]
  subnet_id              = element(module.vpc.private_subnets, 0)
}
module "ui_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  name = "ui-instance"

  ami                    = local.ubuntu_ami
  instance_type          = "t3.micro"
  key_name               = "devops-key"
  monitoring             = true
  vpc_security_group_ids = [module.ui_service_sg.security_group_id, module.ssh_sg.security_group_id]
  subnet_id              = element(module.vpc.private_subnets, 1)
}
module "weather_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  name = "weather-instance"

  ami                    = local.ubuntu_ami
  instance_type          = "t3.micro"
  key_name               = "devops-key"
  monitoring             = true
  vpc_security_group_ids = [module.weather_service_sg.security_group_id, module.ssh_sg.security_group_id]
  subnet_id              = element(module.vpc.private_subnets, 2)
}
module "bastion_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  name = "bastion-instance"

  ami                    = local.ubuntu_ami
  instance_type          = "t3.micro"
  key_name               = "devops-key"
  monitoring             = true
  vpc_security_group_ids = [module.ssh_sg.security_group_id]
  subnet_id              = element(module.vpc.public_subnets, 0)
}
# RDS database
module "db" {
  source                          = "terraform-aws-modules/rds/aws"
  version                         = "5.3.0"
  identifier                      = local.db_name
  engine                          = "mysql"
  engine_version                  = "8.0"
  family                          = "mysql8.0" # DB parameter group
  major_engine_version            = "8.0"      # DB option group
  instance_class                  = "db.t4g.small"
  allocated_storage               = 5
  max_allocated_storage           = 5
  db_name                         = local.db_name
  username                        = local.db_username
  port                            = 3306
  multi_az                        = false
  db_subnet_group_name            = module.vpc.database_subnet_group
  vpc_security_group_ids          = [module.db_sg.security_group_id]
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]
  create_cloudwatch_log_group     = true
  skip_final_snapshot             = true
  deletion_protection             = false
}
# Secrets Manager and Parameter Store
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "moderndevops.db.endpoint"
  type  = "String"
  value = module.db.db_instance_endpoint
}
resource "aws_ssm_parameter" "db_username" {
  name  = "moderndevops.db.username"
  type  = "String"
  value = local.db_username
}
resource "aws_secretsmanager_secret" "db_password" {
  name = "moderndevops.db.password"
}
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = module.db.db_instance_password
}
