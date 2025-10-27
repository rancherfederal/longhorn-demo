# Longhorn Architecture

## Control and data planes

Longhorn is split into control plane and data plane components.

The primary control plane component is the `longhorn-manager`, which is a `DaemonSet` running on all nodes that implements a Kubernetes controller, providing an API that can be called from either the Longhorn UI or from the CSI plugin. In response to a request to create a `PersistentVolume`, the Kubernetes API server calls the `longhorn-csi-plugin`, which then requests the `longhorn-manager` to create a Kubernetes custom resource `Volume`.

When the API server creates the `Volume`, the `longhorn-manager` creates an instance of the `longhorn-engine` on the node the volume will attach to. The `longhorn-engine` is the primary data plane component. For the v1 data engine, a separate `longhorn-engine` instance is created for every volume, serving as an intermediary between the pod and each replica for a volume. Replicas are associated with a particular physical disk on a cluster node, exposed as iSCSI targets, with the engine acting as the iSCSI client or initiator. The `longhorn-engine` exposes volumes as block devices, which the `longhorn-csi-driver` formats and mounts to the cluster node requested. The `kubelet` then bind mounts this into the pod, exposing persistent storage to the application.

Writes to storage pass through the `longhorn-engine`, which synchronously writes data to all replicas backing the volume.

## iSCSI

iSCSI is the Internet Small Computer Systems Interface, called such because it emulates SCSI, usually run over a bus on the motherboard, over an IP network. Software support is required for this, in the form of kernel drivers (`iscsi_tcp` for Linux) and a set of userspace tools usually provided for Linux by the `open-iscsi` project.

A dedicated storage cluster separate from compute nodes is often used in physical storage area network architectures that utilize iSCSI, and a similar setup is often seen with storage providers for Kubernetes. Longhorn, in contrast, does not assume the existence of any resources beyond the cluster nodes themselves, relying upon disks attached to your cluster nodes. As a best practice, these should be separate disks not used for anything else. They do not absolutely *have* to be SSDs, but Longhorn makes no guarantees regarding system stability when needing to account for the additional latency of spinning platter seeks, so SSDs are *highly* recommended.

## Diagram

The following logical diagram is lifted from the Longhorn documentation showing all of these relationships visually.

![Longhorn Overview](static/how-longhorn-works.svg)

This shows an architecture in which each `Volume` is backed by two `Replica`s on a two-node cluster, with each `Replica` scheduled to its own separate disk. This provides high availability via multiple layers of redundancy at both the node level *and* the disk level within each node.