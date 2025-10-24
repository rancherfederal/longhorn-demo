# Volume Backup and Restore

An AWS S3 bucket, IAM user, and access key were already created by Terraform when we created the cluster. We can create a secret from the access key to store in Longhorn. From the `terraform/` subdirectory, run:

```sh
kubectl create secret generic aws-backups-secret \
  --namespace longhorn-system \
  --from-literal=AWS_ACCESS_KEY_ID=$(terraform output backups_access_key_id) \
  --from-literal=AWS_SECRET_ACCESS_KEY=$(terraform output backups_secret_access_key)
```
