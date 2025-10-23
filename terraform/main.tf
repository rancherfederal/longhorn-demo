terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.17"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">=2.3"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

## Network
# default subnet for us-east-1a in default VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "east1a" {
  availability_zone_id = "use1-az4"
  vpc_id               = data.aws_vpc.default.id
}

## Security group
# allow inbound from my IP only, all outbound
resource "aws_security_group" "server" {
  name        = var.resource_name
  description = "Allow inbound traffic for demo and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = var.tag_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = var.allowed_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = var.allowed_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_api_ipv4" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = var.allowed_cidr
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

## IAM
# EC2 instance profile with required API permissions
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# this is needed to create ACME challenge DNS records
# https://cert-manager.io/docs/configuration/acme/dns01/route53/#set-up-an-iam-policy
data "aws_iam_policy_document" "route53_dns_challenge" {
  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["TXT"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "route53_dns_challenge" {
  name        = "route53_dns_challenge"
  description = "Policy for cert-manager to manage dns challenges"
  policy      = data.aws_iam_policy_document.route53_dns_challenge.json
}

resource "aws_iam_role" "server" {
  name               = var.resource_name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "longhorn_demo_dns_challenge" {
  policy_arn = aws_iam_policy.route53_dns_challenge.arn
  role       = aws_iam_role.server.name
}

resource "aws_iam_instance_profile" "server" {
  name = var.resource_name
  role = aws_iam_role.server.name
}

## Server
# EC2 with attached storage
data "cloudinit_config" "server" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "node-init.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/files/node-init.sh")
  }

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = file("${path.module}/files/cloud-config.yaml")
  }
}

data "aws_ami" "server_base" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["${var.ami_prefix}*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "server" {
  ami = data.aws_ami.server_base.id
  iam_instance_profile   = aws_iam_instance_profile.server.name
  instance_type          = var.instance_type
  user_data_base64       = data.cloudinit_config.server.rendered
  vpc_security_group_ids = [aws_security_group.server.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  # /var/lib/rancher
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = var.var_lib_rancher_size
    volume_type = var.var_lib_rancher_type
  }

  # /var/lib/longhorn
  ebs_block_device {
    device_name = "/dev/sdc"
    volume_size = var.var_lib_longhorn_size
    volume_type = var.var_lib_longhorn_type
  }

  metadata_options {
    http_put_response_hop_limit = 3 # default of 1 won't work for containerized cert-manager
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = var.tag_name
  }
}

resource "aws_eip" "server_ip" {
  instance = aws_instance.server.id
  domain   = "vpc"

  tags = {
    Name = var.tag_name
  }
}

# this is assumed to already exist since we don't
# want to register a domain using terraform
data "aws_route53_zone" "domain" {
  name = "${var.domain}."
}

resource "aws_route53_record" "longhorn" {
  name    = "${var.longhorn_host}.${var.domain}"
  records = [aws_eip.server_ip.public_ip]
  ttl     = 300
  type    = "A"
  zone_id = data.aws_route53_zone.domain.zone_id
}