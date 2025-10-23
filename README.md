# Longhorn Demo

## Create resources

From the `terraform/` subdirectory:

```sh
terraform apply -auto-approve
```

## ssh to node

From the `terraform/` subdirectory:

```sh
ssh -o StrictHostKeyChecking=no rocky@$(terraform output server_ip | tr -d '"')
```

Don't turn off host key checking in general. This is for DEMO PURPOSES ONLY! 

## Install Resources

Install cert-manager:

```sh
kubectl create -f manifests/cert-manager.yaml
```

Watch the logs to see it install:

```sh
kubectl logs jobs/helm-install-cert-manager -n kube-system -f
```

Create the `ClusterIssuer` for Let's Encrypt and the `Certificate` for the Longhorn UI ingress:

```sh
kubectl create -f manifests/issuer.yaml
kubectl create -f manifests/certificate.yaml
```

Watch for the certificate to be issued:

```sh
watch kubectl get certificate -n longhorn-system longhorn
```

Assuming the certificates exist, we can create the secret for mTLS:

```sh
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-grpc-tls
  namespace: longhorn-system
type: kubernetes.io/tls
data:
  ca.crt: $(base64 -w0 pki/ca.crt)
  tls.crt: $(base64 -w0 pki/tls.crt)
  tls.key: $(base64 -w0 pki/tls.key)
EOF
```

Otherwise, see [PKI](./docs/pki.md) for instructions on issuing the required certificate and key.

Create the Traefik `Middleware` for basic auth:

```sh
kubectl create -f manifests/middleware.yaml
```

Install Longhorn:

```sh
kubectl create -f manifests/longhorn.yaml
```

Note that the secret for basic auth will have already been created, along with the `longhorn-system` namespace, by `cloud-init` when the node first launches, in order to randomly generate the password. To retrieve it:

```sh
kubectl get secret -n longhorn-system authsecret -ogo-template='{{.data.password | base64decode}}'
```

The username is `longhorn`. Navigate to the [Longhorn UI](https://longhorn.rgsdemo.com) and a pop-up should appear prompting you for the username and password.

## Demo run-through

Instructions for setting up a certificate and tls secret to enable mTLS can be found in [pki](./docs/pki.md). This can be done before Longhorn is deployed or after. If after, then the `longhorn-manager` and `instance-manager` pods will need to be bounced to mount the secret. No settings need to be changed, as they automatically detect its presence and fall back to unauthenticated comms if not. The demo itself is walked through in the following order:
- [Architecture](./docs/arch.md)
- [Creating Volumes](./docs/volumes.md)
- [ReadWriteMany Volumes](./docs/rwx.md)
- [Backup and Restore](./docs/backup.md)
- [Security](./docs/security.md)
