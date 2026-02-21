# NFS Storage Setup (Server `192.168.1.117`)

This guide shows how to use NFS shares from `192.168.1.117` in this cluster.

## Quick apply (files in this folder)

```bash
kubectl create namespace jellyfin --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f setup/09_storage/nfs-config-pv-pvc.yaml
kubectl apply -f setup/09_storage/nfs-media-pv-pvc.yaml
kubectl apply -f setup/09_storage/nfs-test-pod.yaml

kubectl get pv
kubectl get pvc -n jellyfin
kubectl -n jellyfin exec -it nfs-test -- sh
```

## 1) Prepare the NFS server

On `192.168.1.117`, ensure the share is exported and reachable by cluster nodes.

Example `/etc/exports`:

```exports
/srv/nfs/media 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/config 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
```

Apply exports:

```bash
sudo exportfs -ra
sudo exportfs -v
```

## 2) Install NFS client packages on every Kubernetes node

Run on control-plane and worker nodes:

```bash
sudo apt-get update
sudo apt-get install -y nfs-common
```

Quick connectivity check from a node:

```bash
showmount -e 192.168.1.117
```

## 3) Static provisioning (recommended first)

Create one `PersistentVolume` per NFS path, then bind with `PersistentVolumeClaim`.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
	name: nfs-media-pv
spec:
	capacity:
		storage: 2Ti
	accessModes:
		- ReadWriteMany
	persistentVolumeReclaimPolicy: Retain
	storageClassName: nfs-static
	mountOptions:
		- nfsvers=4.1
	nfs:
		server: 192.168.1.117
		path: /srv/nfs/media
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
	name: nfs-media-pvc
	namespace: jellyfin
spec:
	accessModes:
		- ReadWriteMany
	resources:
		requests:
			storage: 2Ti
	storageClassName: nfs-static
	volumeName: nfs-media-pv
```

Apply:

```bash
kubectl create namespace jellyfin --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f nfs-media-pv-pvc.yaml
kubectl get pv,pvc -n jellyfin
```

## 4) Test mount from inside the cluster

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: nfs-test
	namespace: jellyfin
spec:
	containers:
		- name: shell
			image: busybox:1.36
			command: ["sh", "-c", "sleep 3600"]
			volumeMounts:
				- name: media
					mountPath: /mnt/media
	volumes:
		- name: media
			persistentVolumeClaim:
				claimName: nfs-media-pvc
```

```bash
kubectl apply -f nfs-test-pod.yaml
kubectl -n jellyfin exec -it nfs-test -- sh
ls -la /mnt/media
```

## 5) Use with Jellyfin (Helm values)

In your Jellyfin values file, point volumes to existing claims (do not rely on local node storage for media).

Pattern to use:

```yaml
persistence:
	config:
		enabled: true
		existingClaim: nfs-config-pvc
	media:
		enabled: true
		existingClaim: nfs-media-pvc
```

Then apply:

```bash
helm upgrade --install jellyfin jellyfin/jellyfin -f applications/jellyfin/values.yaml --namespace jellyfin --create-namespace
```

## 5b) Verify Jellyfin is using NFS claims

Check claims are bound:

```bash
kubectl -n jellyfin get pvc
kubectl get pv | grep -E 'nfs-(config|media)-pv'
```

Confirm Jellyfin pod references the expected PVC names:

```bash
kubectl -n jellyfin get pod -l app.kubernetes.io/name=jellyfin -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{range .spec.volumes[*]}{.name}{": "}{.persistentVolumeClaim.claimName}{"\n"}{end}{"\n"}{end}'
```

Check the mounts from inside the running Jellyfin container:

```bash
POD=$(kubectl -n jellyfin get pod -l app.kubernetes.io/name=jellyfin -o jsonpath='{.items[0].metadata.name}')
kubectl -n jellyfin exec -it "$POD" -- sh -c 'df -h | grep -E "/config|/media"; ls -la /config; ls -la /media'
```

Write a test file and verify it appears on NFS server path:

```bash
kubectl -n jellyfin exec -it "$POD" -- sh -c 'date > /media/nfs-write-test.txt && ls -l /media/nfs-write-test.txt'
```

Cleanup test artifacts:

```bash
kubectl -n jellyfin exec -it "$POD" -- sh -c 'rm -f /media/nfs-write-test.txt'
kubectl -n jellyfin delete pod nfs-test --ignore-not-found
```

## 6) Optional: dynamic provisioning (advanced)

If you want PVCs to auto-create subdirectories on NFS, install `nfs-subdir-external-provisioner` and create a `StorageClass`.

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm upgrade --install nfs-client nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
	--namespace nfs-provisioner --create-namespace \
	--set nfs.server=192.168.1.117 \
	--set nfs.path=/srv/nfs \
	--set storageClass.name=nfs-client \
	--set storageClass.defaultClass=false
```

Example PVC using dynamic class:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
	name: dynamic-nfs-pvc
	namespace: jellyfin
spec:
	accessModes:
		- ReadWriteMany
	resources:
		requests:
			storage: 50Gi
	storageClassName: nfs-client
```

## Troubleshooting

- `PVC Pending`: check `kubectl describe pvc <name> -n <ns>` and verify `storageClassName`/`volumeName` match.
- Mount errors: verify `nfs-common` is installed on all nodes.
- Permission denied: check server export options and ownership/permissions on NFS directories.
- Slow or stale mounts: add or tune NFS `mountOptions` in the PV.
