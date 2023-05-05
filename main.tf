data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux_x86_64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = "${var.prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs            = data.aws_availability_zones.available.names
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 60
  flow_log_cloudwatch_log_group_name_prefix       = "${var.prefix}-vpc-flow-logs-"

  map_public_ip_on_launch = false
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name        = "${var.prefix}-jenkins-sg"
  description = "Security group for jenkins server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow all traffic through port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my computer"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["179.190.243.148/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

################################################################################
# EC2 Instance
################################################################################

resource "aws_instance" "jenkins_server" {

  ami                    = data.aws_ami.amazon_linux_x86_64.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.this.id]
  subnet_id              = module.vpc.public_subnets[0]

  iam_instance_profile = aws_iam_instance_profile.this.name
  user_data = templatefile("${path.module}/${var.user_data_template}", {
    user_data = join("\n", var.user_data)
    ssh_user  = var.ssh_user
  })

  tags = merge(
    {
      Name = "jenkins-server"
    }
  )
}

resource "aws_eip" "this" {
  instance = aws_instance.jenkins_server.id
  vpc      = true
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.jenkins_server.id
  allocation_id = aws_eip.this.id
}

################################################################################
# SSM Role
################################################################################

locals {
  role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
  ]
}

resource "aws_iam_role" "this" {
  name = "AmazonEC2RoleforSSM"
  path = "/system/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "this" {
  name = "SessionManagerPermissions"
  role = aws_iam_role.this.id
  policy = templatefile("./policies/instance-session-manager-policy.json", {
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "AmazonSSMManagedInstanceCore"
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(local.role_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = element(local.role_policy_arns, count.index)
}
