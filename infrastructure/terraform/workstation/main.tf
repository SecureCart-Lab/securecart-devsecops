
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

locals {
  az = "us-east-1a"
}

resource "aws_vpc" "workstation" {
  #checkov:skip=CKV2_AWS_11:VPC flow logs are outside the scope of this learning lab.

  cidr_block           = "10.30.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "securecart-workstation-vpc"
  }
}

resource "aws_internet_gateway" "workstation" {
  vpc_id = aws_vpc.workstation.id

  tags = {
    Name = "securecart-workstation-igw"
  }
}

resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130:Lab workstation requires a public IP for direct SSH access.

  vpc_id                  = aws_vpc.workstation.id
  cidr_block              = "10.30.0.0/28"
  availability_zone       = local.az
  map_public_ip_on_launch = true

  tags = {
    Name = "securecart-workstation-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.workstation.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.workstation.id
  }

  tags = {
    Name = "securecart-workstation-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_default_security_group" "workstation" {
  vpc_id = aws_vpc.workstation.id

  ingress = []
  egress  = []
}

resource "aws_security_group" "workstation" {
  #checkov:skip=CKV_AWS_382:Lab workstation requires outbound internet access for package downloads and updates.

  name_prefix = "securecart-workstation-"
  description = "SecureCart workstation SSH from one trusted public IP"
  vpc_id      = aws_vpc.workstation.id

  ingress {
    description = "SSH from learner IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    description = "Allow outbound internet access for package downloads and updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "securecart-workstation-sg"
  }
}

resource "aws_instance" "workstation" {
  #checkov:skip=CKV_AWS_88:Lab workstation requires a public IP for direct SSH access.
  #checkov:skip=CKV2_AWS_41:Lab workstation does not require AWS API permissions, so no IAM instance role is attached.

  ami                         = data.aws_ssm_parameter.ubuntu.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.workstation.id]

  ebs_optimized = true
  monitoring    = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "securecart-workstation"
  }
}
