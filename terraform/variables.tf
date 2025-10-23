variable "allowed_cidr" {
  type = string
  description = "CIDR to allow ssh and tls ingress from"
  # curl ipv4.icanhazip.com
  default = "76.185.97.220/32"
}

variable "ami_prefix" {
  type = string
  description = "Prefix for AMI name to query for"
  # beware this requires subscribing in advance,
  # which is a one-time op per account
  default = "Rocky-9-EC2-Base-9"
}

variable "aws_region" {
  type = string
  description = "AWS region to create resources in"
  # iffy?
  default = "us-east-1"
}

variable "domain" {
  type = string
  description = "Domain to place app subdomains under"
  default = "rgsdemo.com"
}

variable "instance_type" {
  type = string
  description = "Instance type of single-node cluster server"
  # cheapest instance type w/ 10G network
  default = "m5a.xlarge"
}

variable "longhorn_host" {
  type = string
  description = "Subdomain host for Longhorn UI"
  default = "longhorn"
}

variable "resource_name" {
  type = string
  description = "Name to add to resources that display this in AWS console"
  default = "longhorn-demo"
}

variable "root_volume_size" {
  type = string
  description = "Size of root volume may be smaller than AMI due to separate volumes for storage"
  default = "40"
}

variable "root_volume_type" {
  type = string
  description = "Volume type for root volume"
  default = "gp3"
}

variable "tag_name" {
  type = string
  description = "tag:Name to add to resources that display this in AWS console"
  default = "longhorn-demo"
}

variable "var_lib_longhorn_size" {
  type = string
  description = "Size of volume to mount to /var/lib/longhorn"
  default = "1024"
}

variable "var_lib_longhorn_type" {
  type = string
  description = "Volume type to mount to /var/lib/longhorn"
  default = "gp3"
}

variable "var_lib_rancher_size" {
  type = string
  description = "Size of volume to mount to /var/lib/rancher"
  default = "100"
}

variable "var_lib_rancher_type" {
  type = string
  description = "Volume type to mount to /var/lib/rancher"
  default = "gp3"
}