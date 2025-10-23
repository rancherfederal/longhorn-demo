# Longhorn volumes in action

First, create a namespace that resources will reside in:

```sh
kubectl create ns longhorn-demo
```

## Create resources with peristent storage

```sh
kubectl create -f manifests/pod_with_pvc.yaml
```

```sh
kubectl create -f manifests/statefulset.yaml
```

See the volumes being created. The Longhorn custom resource `Volume` exists in the `longhorn-system` namespace.

```sh
kubectl get volumes.longhorn.io -n longhorn-system
```
```
NAME                                       DATA ENGINE   STATE      ROBUSTNESS   SCHEDULED   SIZE         NODE                            AGE
pvc-89c15dec-5de1-4b58-b791-7fd23d50025b   v1            attached   healthy                  2147483648   ip-172-31-83-248.ec2.internal   102m
pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f   v1            attached   healthy                  1073741824   ip-172-31-83-248.ec2.internal   27m
pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152   v1            attached   healthy                  1073741824   ip-172-31-83-248.ec2.internal   34m
```

The corresponding `PersistentVolumeClaim` objects are in the `demo` namespace:

```sh
kubectl get pvc -n demo
```
```
NAME                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
longhorn-volv-pvc   Bound    pvc-89c15dec-5de1-4b58-b791-7fd23d50025b   2Gi        RWO            longhorn       <unset>                 104m
www-web-0           Bound    pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152   1Gi        RWO            longhorn       <unset>                 35m
www-web-1           Bound    pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f   1Gi        RWO            longhorn       <unset>                 28m
```

## Observe block devices created

On the cluster node itself, we can now see the block devices that were created by the `longhorn-engine`, along with their corresponding bind mounts created by the `kubelet`.

```
[root@ip-172-31-83-248 ~]# lsblk
NAME MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
sda    8:0    0    2G  0 disk  /var/lib/kubelet/pods/cbec4259-f5b9-43c6-9ecf-096dba758668/volumes/kubernetes.io~csi/pvc-89c15dec-5de1-4b58-b791-7fd23d50025b/mount
                               /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/59cf644090dc8a27d789b0f496d04ba9854a46b20971b448ff5724899
                               57b76ec/globalmount
sdb    8:16   0    1G  0 disk  /var/lib/kubelet/pods/a476f5be-ad29-4bad-a133-c19f56dbb315/volumes/kubernetes.io~csi/pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152/mount
                               /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/718c24a54c3a1e77b7233c9bf9c587b6cf3726d92fb23e696410e9752
                               aa23030/globalmount
sdc    8:32   0    1G  0 disk  /var/lib/kubelet/pods/15bd1932-07f6-4803-b8fa-ec73a2c57312/volumes/kubernetes.io~csi/pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f/mount
                               /var/lib/kubelet/plugins/kubernetes.io/csi/driver.longhorn.io/93d48e653f6aef1d4aab606f6275971ef1f63db92443690463b291b87
                               d8c49ef/globalmount
```

We see there now exist devices `/dev/sda`, `/dev/sdb`, and `/dev/sdc`. We can inspect to see these are not true SCSI devices:

```
[root@ip-172-31-83-248 ~]# PAGER="" udevadm info /dev/sda
P: /devices/platform/host0/session1/target0:0:0/0:0:0:1/block/sda
M: sda
U: block
T: disk
D: b 8:0
N: sda
L: 0
S: disk/by-path/ip-10.42.0.34:3260-iscsi-iqn.2019-10.io.longhorn:pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-lun-1
S: disk/by-id/scsi-360000000000000000e00000000010001
S: disk/by-diskseq/9
S: disk/by-id/scsi-1IET_00010001
S: disk/by-id/scsi-SIET_VIRTUAL-DISK_beaf11
S: disk/by-id/wwn-0x60000000000000000e00000000010001
S: disk/by-id/scsi-33000000100000001
Q: 9
E: DEVPATH=/devices/platform/host0/session1/target0:0:0/0:0:0:1/block/sda
E: DEVNAME=/dev/sda
E: DEVTYPE=disk
E: DISKSEQ=9
E: MAJOR=8
E: MINOR=0
E: SUBSYSTEM=block
E: USEC_INITIALIZED=46753988769
E: ID_SCSI=1
E: ID_VENDOR=IET
E: ID_VENDOR_ENC=IET\x20\x20\x20\x20\x20
E: ID_MODEL=VIRTUAL-DISK
E: ID_MODEL_ENC=VIRTUAL-DISK\x20\x20\x20\x20
E: ID_REVISION=0001
E: ID_TYPE=disk
E: ID_SERIAL=360000000000000000e00000000010001
E: ID_SERIAL_SHORT=60000000000000000e00000000010001
E: ID_WWN=0x6000000000000000
E: ID_WWN_VENDOR_EXTENSION=0x0e00000000010001
E: ID_WWN_WITH_EXTENSION=0x60000000000000000e00000000010001
E: ID_SCSI_SERIAL=beaf11
E: ID_BUS=scsi
E: ID_PATH=ip-10.42.0.34:3260-iscsi-iqn.2019-10.io.longhorn:pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-lun-1
E: ID_PATH_TAG=ip-10_42_0_34_3260-iscsi-iqn_2019-10_io_longhorn_pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-lun-1
E: SCSI_TPGS=0
E: SCSI_TYPE=disk
E: SCSI_VENDOR=IET
E: SCSI_VENDOR_ENC=IET\x20\x20\x20\x20\x20
E: SCSI_MODEL=VIRTUAL-DISK
E: SCSI_MODEL_ENC=VIRTUAL-DISK\x20\x20\x20\x20
E: SCSI_REVISION=0001
E: ID_SCSI_INQUIRY=1
E: SCSI_IDENT_SERIAL=beaf11
E: SCSI_IDENT_LUN_T10=IET_00010001
E: SCSI_IDENT_LUN_NAA_LOCAL=3000000100000001
E: SCSI_IDENT_LUN_NAA_REGEXT=60000000000000000e00000000010001
E: MPATH_SBIN_PATH=/sbin
E: DM_MULTIPATH_DEVICE_PATH=0
E: NVME_HOST_IFACE=none
E: DEVLINKS=/dev/disk/by-path/ip-10.42.0.34:3260-iscsi-iqn.2019-10.io.longhorn:pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-lun-1 /dev/disk/by-id/scsi-360000000000000000e00000000010001 /dev/disk/by-diskseq/9 /dev/disk/by-id/scsi-1IET_00010001 /dev/disk/by-id/scsi-SIET_VIRTUAL-DISK_beaf11 /dev/disk/by-id/wwn-0x60000000000000000e00000000010001 /dev/disk/by-id/scsi-33000000100000001
E: TAGS=:systemd:
E: CURRENT_TAGS=:systemd:
```

Note the IP in the device paths. This is the IP of the instance manager pod:

```sh
kubectl get pod -n longhorn-system -l longhorn.io/component=instance-manager -o=jsonpath="{range .items[*]}{.status.podIP}"
```
```
10.42.0.34
```

Go back on the host and we see all of the `longhorn-engine` instances:

```
[root@ip-172-31-83-248 ~]# ps -aeo args | grep '^/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn' | sed 's/--/\n  --/g'
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-89c15dec-5de1-4b58-b791-7fd23d50025b replica /host/var/lib/longhorn/replicas/pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-733eabeb
  --size 2147483648
  --disableRevCounter
  --replica-instance-name pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-r-c0b0aaf5
  --snapshot-max-count 250
  --snapshot-max-size 0
  --sync-agent-port-count 7
  --listen 0.0.0.0:10000
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-89c15dec-5de1-4b58-b791-7fd23d50025b replica /host/var/lib/longhorn/replicas/pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-841fa34c
  --size 2147483648
  --disableRevCounter
  --replica-instance-name pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-r-48313674
  --snapshot-max-count 250
  --snapshot-max-size 0
  --sync-agent-port-count 7
  --listen 0.0.0.0:10010
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-89c15dec-5de1-4b58-b791-7fd23d50025b sync-agent
  --listen 0.0.0.0:10002
  --replica 0.0.0.0:10000
  --listen-port-range 10003-10009
  --replica-instance-name pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-r-c0b0aaf5
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-89c15dec-5de1-4b58-b791-7fd23d50025b sync-agent
  --listen 0.0.0.0:10012
  --replica 0.0.0.0:10010
  --listen-port-range 10013-10019
  --replica-instance-name pvc-89c15dec-5de1-4b58-b791-7fd23d50025b-r-48313674
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152 replica /host/var/lib/longhorn/replicas/pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152-920821dc
  --size 1073741824
  --disableRevCounter
  --replica-instance-name pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152-r-9990ae73
  --snapshot-max-count 250
  --snapshot-max-size 0
  --sync-agent-port-count 7
  --listen 0.0.0.0:10042
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152 sync-agent
  --listen 0.0.0.0:10044
  --replica 0.0.0.0:10042
  --listen-port-range 10045-10051
  --replica-instance-name pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152-r-9990ae73
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152 replica /host/var/lib/longhorn/replicas/pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152-5dc65752
  --size 1073741824
  --disableRevCounter
  --replica-instance-name pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152-r-cf12fbd6
  --snapshot-max-count 250
  --snapshot-max-size 0
  --sync-agent-port-count 7
  --listen 0.0.0.0:10052
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152 sync-agent
  --listen 0.0.0.0:10054
  --replica 0.0.0.0:10052
  --listen-port-range 10055-10061
  --replica-instance-name pvc-f1c2d445-7667-4fd7-9ae4-0196af70e152-r-cf12fbd6
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f replica /host/var/lib/longhorn/replicas/pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f-5ba606f3
  --size 1073741824
  --disableRevCounter
  --replica-instance-name pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f-r-a373c535
  --snapshot-max-count 250
  --snapshot-max-size 0
  --sync-agent-port-count 7
  --listen 0.0.0.0:10063
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f replica /host/var/lib/longhorn/replicas/pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f-c32207cf
  --size 1073741824
  --disableRevCounter
  --replica-instance-name pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f-r-c6cf5160
  --snapshot-max-count 250
  --snapshot-max-size 0
  --sync-agent-port-count 7
  --listen 0.0.0.0:10073
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f sync-agent
  --listen 0.0.0.0:10065
  --replica 0.0.0.0:10063
  --listen-port-range 10066-10072
  --replica-instance-name pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f-r-a373c535
/host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn
  --volume-name pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f sync-agent
  --listen 0.0.0.0:10075
  --replica 0.0.0.0:10073
  --listen-port-range 10076-10082
  --replica-instance-name pvc-b636e828-6c7e-413f-8cd3-f292d8cd8d8f-r-c6cf5160
```

We see there are now 12 of these, which correspond to 2 replicas and 1 sync agent for each of the three volumes we created. There is some inconsistency here with the Longhorn documentation, which implies a new pod is created for each `longhorn-engine` instance, which may have been the case in the past. In Longhorn as it exists today, the instance manager is instead started with the containerized init process `tini`, which helps a single container launch and manage many processes.

An excerpt from `ps x --forest` shows the relationship:

```
6369 ?        Sl     0:43 /var/lib/rancher/k3s/data/86a616cdaf0fb57fa13670ac5a16f1699f4b2be4772e842d97904c69698ffdc2/bin/containerd-shim-runc-v2 -n
  11555 ?        Ss     0:01  \_ /tini -- instance-manager --debug daemon --listen 0.0.0.0:8500
  11568 ?        Sl     1:40      \_ longhorn-instance-manager --debug daemon --listen 0.0.0.0:8500
  11572 ?        Sl     0:02          \_ tgtd -f
  11573 ?        S      0:00          \_ tee /var/log/tgtd.log
 635817 ?        Sl     0:02          \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-89c15dec-
 635839 ?        Sl     0:03          |   \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-89c15
 635830 ?        Sl     0:02          \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-89c15dec-
 635849 ?        Sl     0:03          |   \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-89c15
 635899 ?        Sl     0:14          \_ /engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --engine-instance-name pvc-89c15dec-5de1-4b58-b79
 715562 ?        Sl     0:00          \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-f1c2d445-
 715571 ?        Sl     0:01          |   \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-f1c2d
 715595 ?        Sl     0:00          \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-f1c2d445-
 715604 ?        Sl     0:01          |   \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-f1c2d
 715621 ?        Sl     0:04          \_ /engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --engine-instance-name pvc-f1c2d445-7667-4fd7-9ae
 716314 ?        Sl     0:00          \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-b636e828-
 716323 ?        Sl     0:01          |   \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-b636e
 716321 ?        Sl     0:00          \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-b636e828-
 716338 ?        Sl     0:01          |   \_ /host/var/lib/longhorn/engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --volume-name pvc-b636e
 716447 ?        Sl     0:04          \_ /engine-binaries/longhornio-longhorn-engine-v1.9.2/longhorn --engine-instance-name pvc-b636e828-6c7e-413f-8cd
```
