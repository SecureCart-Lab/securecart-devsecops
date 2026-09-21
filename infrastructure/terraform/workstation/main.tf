data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

locals {
  az = data.aws_availability_zones.available.names[0]
}

resource "aws_vpc" "workstation" {
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

resource "aws_security_group" "workstation" {
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
  ami                         = data.aws_ssm_parameter.ubuntu.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.workstation.id]

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

  # Avoid T-family surplus-credit charges in a learning environment.
  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "securecart-workstation"
  }
}
