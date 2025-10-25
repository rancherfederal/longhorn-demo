#!/bin/sh

# format disks before multipathd takes them over
# possibly better way to do this using nvme-cli to query the bdev name
# that corresponds to the device name in AWS EBS service, but
# this is expedient given the size is unique to each disk
VAR_LIB_RANCHER_DEV=$(lsblk | grep '100G' | head -n 1 | awk '{print $1}')
VAR_LIB_LONGHORN_DEV=$(lsblk | grep '1T' | head -n 1 | awk '{print $1}')

parted -s "/dev/${VAR_LIB_RANCHER_DEV}" mklabel gpt
parted -s -a opt "/dev/${VAR_LIB_RANCHER_DEV}" mkpart "Linux" ext4 1MiB 100%
mkfs.ext4 -G 4096 -L "rancher" "/dev/${VAR_LIB_RANCHER_DEV}p1"

parted -s "/dev/${VAR_LIB_LONGHORN_DEV}" mklabel gpt
parted -s -a opt "/dev/${VAR_LIB_LONGHORN_DEV}" mkpart "Linux" ext4 1MiB 100%
mkfs.ext4 -G 4096 -L "longhorn" "/dev/${VAR_LIB_LONGHORN_DEV}p1"

RANCHER_UUID=$(blkid -s UUID -o value "/dev/${VAR_LIB_RANCHER_DEV}p1")
LONGHORN_UUID=$(blkid -s UUID -o value "/dev/${VAR_LIB_LONGHORN_DEV}p1")

mkdir -p /var/lib/rancher
mkdir -p /var/lib/longhorn

echo "UUID=${RANCHER_UUID} /var/lib/rancher ext4 defaults 0 2" >> /etc/fstab
echo "UUID=${LONGHORN_UUID} /var/lib/longhorn ext4 defaults 0 2" >> /etc/fstab

systemctl daemon-reload
mount -a

# need public ip in kubeconfig cert to access from outside
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
echo "tls-san:" >> /etc/rancher/k3s/config.yaml
echo "  - $PUBLIC_IP" >> /etc/rancher/k3s/config.yaml

# installing k3s also starts it
curl -fsLS "https://get.k3s.io" | INSTALL_K3S_CHANNEL=stable sh -

# kernel modules required by longhorn
sudo modprobe -a dm_crypt iscsi_tcp nfs

# services required by longhorn
systemctl enable multipathd
systemctl start multipathd
systemctl enable iscsid
systemctl start iscsid

# conveniences
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /root/.bashrc
echo "export CRI_CONFIG_FILE=/var/lib/rancher/k3s/agent/etc/crictl.yaml" >> /root/.bashrc

# wait for k3s to be up - won't take 10 minutes, but being safe
timeout 10m bash -c 'until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 1; done'

# create the basic auth secret for longhorn-ui and the encrypted storage class secret
#
# this is NOT the secure way to store a password for basic auth since it doesn't hash
# the password, but we do it this way in order to be able to retrieve the password
# for use without knowing what it is in advance, since it is randomly generated
#
# the preferred way to store basic auth is to create a user file using htpasswd
# and store it in an Opaque secret under the key 'auth', which standard ingress
# controllers including traefik can use
cat <<EOF | /usr/local/bin/kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml create -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: longhorn-system
---
apiVersion: v1
kind: Secret
metadata:
  name: authsecret
  namespace: longhorn-system
type: kubernetes.io/basic-auth
stringData:
  username: longhorn
  password: $(openssl rand -hex 16)
---
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-crypto-key
  namespace: longhorn-system
stringData:
  CRYPTO_KEY_VALUE: $(openssl rand -hex 16)
  CRYPTO_KEY_PROVIDER: secret
  CRYPTO_KEY_CIPHER: aes-xts-plain64
  CRYPTO_KEY_HASH: sha256
  CRYPTO_KEY_SIZE: "256"
  CRYPTO_PBKDF: argon2i
EOF

# copy the kubeconfig to default user so you can scp it back to your own workstation
cp /etc/rancher/k3s/k3s.yaml /home/rocky/ && chown rocky:rocky /home/rocky/k3s.yaml
sed -i "s/server:.*/server: https:\/\/$PUBLIC_IP:6443/" /home/rocky/k3s.yaml