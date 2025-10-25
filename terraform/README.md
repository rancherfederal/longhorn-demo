<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=6.17 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >=2.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.18.0 |
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | 2.3.7 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.server_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_access_key.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_instance_profile.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.route53_dns_challenge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.longhorn_demo_dns_challenge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_user.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy_attachment.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_instance.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_route53_record.longhorn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_security_group.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_api_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_ssh_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_tls_ipv4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_ami.server_base](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.backups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.route53_dns_challenge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnet.east1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [cloudinit_config.server](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidr"></a> [allowed\_cidr](#input\_allowed\_cidr) | CIDR to allow ssh and tls ingress from | `string` | n/a | yes |
| <a name="input_ami_prefix"></a> [ami\_prefix](#input\_ami\_prefix) | Prefix for AMI name to query for | `string` | `"Rocky-10-EC2-Base-10"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to create resources in | `string` | `"us-east-1"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain to place app subdomains under | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type of single-node cluster server | `string` | `"m5a.xlarge"` | no |
| <a name="input_longhorn_host"></a> [longhorn\_host](#input\_longhorn\_host) | Subdomain host for Longhorn UI | `string` | `"longhorn"` | no |
| <a name="input_resource_name"></a> [resource\_name](#input\_resource\_name) | Name to add to resources that display this in AWS console | `string` | `"longhorn-demo"` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size of root volume may be smaller than AMI due to separate volumes for storage | `string` | `"40"` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | Volume type for root volume | `string` | `"gp3"` | no |
| <a name="input_tag_name"></a> [tag\_name](#input\_tag\_name) | tag:Name to add to resources that display this in AWS console | `string` | `"longhorn-demo"` | no |
| <a name="input_var_lib_longhorn_size"></a> [var\_lib\_longhorn\_size](#input\_var\_lib\_longhorn\_size) | Size of volume to mount to /var/lib/longhorn | `string` | `"1024"` | no |
| <a name="input_var_lib_longhorn_type"></a> [var\_lib\_longhorn\_type](#input\_var\_lib\_longhorn\_type) | Volume type to mount to /var/lib/longhorn | `string` | `"gp3"` | no |
| <a name="input_var_lib_rancher_size"></a> [var\_lib\_rancher\_size](#input\_var\_lib\_rancher\_size) | Size of volume to mount to /var/lib/rancher | `string` | `"100"` | no |
| <a name="input_var_lib_rancher_type"></a> [var\_lib\_rancher\_type](#input\_var\_lib\_rancher\_type) | Volume type to mount to /var/lib/rancher | `string` | `"gp3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backups_access_key_id"></a> [backups\_access\_key\_id](#output\_backups\_access\_key\_id) | AWS\_ACCESS\_KEY\_ID value to inject into s3 backup secret |
| <a name="output_backups_secret_access_key"></a> [backups\_secret\_access\_key](#output\_backups\_secret\_access\_key) | AWS\_SECRET\_ACCESS\_KEY value to inject into s3 backup secret |
| <a name="output_server_ip"></a> [server\_ip](#output\_server\_ip) | Elastic IP attached to server for ingress |
<!-- END_TF_DOCS -->