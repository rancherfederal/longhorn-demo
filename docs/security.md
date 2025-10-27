# Longhorn data security

## Data in-transit

iSCSI normally provides authentication using CHAP, but in practice is often run without authentication, instead relying on network isolation with a dedicated storage network either physically isolated or on its own VLAN. As Longhorn is running in Kubernetes, Kubernetes-native mechanisms are used to achieve the same. Though these are turned off by default, network policies can be turned on as a Helm value option restricting access to the replicas that expose iSCSI ports, and mTLS may be enabled to authenticate and encrypt storage network traffic. Alternatively, a service mesh can be used to accomplish these same features.

## Data at-rest

Longhorn encrypts volumes at rest using the `dm_crypt` kernel module and `cryptsetup` userspace tools, which must be installed on each host acting as a Longhorn storage node. Encryption of volumes in filesystem mode has been supported since Longhorn 1.2 and block mode since 1.6. Encryption keys must be stored as Kubernetes secrets and storage class parameters instruct Longhorn to use these.

To create an encrypted storage class:

```sh
kubectl create -f manifests/encrypted-storage-class.yaml
```

Create an example pod that mounts an encrypted volume:

```sh
kubectl create -f manifests/pod-with-encrypted-pvc.yaml
```

On the host, we see we now have a block device of type `crypto_LUKS`:

```
[root@ip-172-31-83-248 ~]# blkid /dev/sdd
/dev/sdd: UUID="40dc0876-6bd0-4e46-b57c-783f1c8ad674" TYPE="crypto_LUKS"
```

Delete the pod to unmount the data:

```sh
kubectl delete pod -n longhorn-demo encrypted-volume-test
```

Now on the host observe the backing image of one of the replicas:

```
[root@ip-172-31-83-248 ~]# file /var/lib/longhorn/replicas/pvc-6b9bec4c-f315-47f4-bab4-9c9dead7a3ad-430e1f1e/volume-head-000.img
/var/lib/longhorn/replicas/pvc-6b9bec4c-f315-47f4-bab4-9c9dead7a3ad-430e1f1e/volume-head-000.img: LUKS encrypted file, ver 2 [, , sha256] UUID: 40dc0876-6bd0-4e46-b57c-783f1c8ad674
```

We have a LUKS encrypted file.
