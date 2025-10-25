output "server_ip" {
  description = "Elastic IP attached to server for ingress"
  value       = aws_eip.server_ip.public_ip
}

output "backups_access_key_id" {
  description = "AWS_ACCESS_KEY_ID value to inject into s3 backup secret"
  value       = aws_iam_access_key.backups.id
}

output "backups_secret_access_key" {
  description = "AWS_SECRET_ACCESS_KEY value to inject into s3 backup secret"
  sensitive   = true
  value       = aws_iam_access_key.backups.secret
}
