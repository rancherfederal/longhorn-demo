output "server_ip" {
  value = aws_eip.server_ip.public_ip
}

output "backups_access_key_id" {
  value = aws_iam_access_key.backups.id
}

output "backups_secret_access_key" {
  sensitive = true
  value     = aws_iam_access_key.backups.secret
}
