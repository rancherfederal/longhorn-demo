# Setting up certificates

## CA

```sh
openssl genrsa -out ca.key 4096
```

```sh
openssl req -x509 -new -sha512 -noenc \
  -key ca.key -days 3653 \
  -config ca.conf \
  -out ca.crt
```

## Longhorn

```sh
openssl genrsa -out tls.key 4096
```

```sh
openssl req -new -key tls.key -sha256 \
  -config ca.conf -section longhorn-backend \
  -out tls.csr
```

```sh
openssl x509 -req -days 365 -in tls.csr \
  -copy_extensions copyall \
  -sha256 -CA ca.crt \
  -CAkey ca.key \
  -CAcreateserial \
  -out tls.crt
```

## Create the secret

This assumes the namespace already exists. If not, `kubectl create ns longhorn-system`. This does not need to exist prior to installation, but `instance-manager` and `longhorn-manager` pods will need to be bounced to pick it up if not.

```sh
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-grpc-tls
  namespace: longhorn-system
type: kubernetes.io/tls
data:
  ca.crt: $(base64 -w0 ca.crt)
  tls.crt: $(base64 -w0 tls.crt)
  tls.key: $(base64 -w0 tls.key)
EOF
```
