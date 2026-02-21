# Jellyfin Rebuild (LAN-only via Istio)

This folder captures a repeatable rebuild for Jellyfin with:

- NFS-backed storage claims
- Dedicated Istio Gateway for `jellyfin.itosbl.com`
- LAN-only access policy (`192.168.1.0/24`)
- Traefik ingress disabled for Jellyfin via Helm values override

## One-command bootstrap

From repo root:

```bash
bash applications/jellyfin/rebuild/rebuild-jellyfin.sh
```

## What this applies

- `setup/09_storage/nfs-config-pv-pvc.yaml`
- `setup/09_storage/nfs-media-pv-pvc.yaml`
- `applications/jellyfin/istio-jellyfin-lan-gateway.yaml`
- `applications/jellyfin/istio-jellyfin-local-only.yaml`
- Helm release with:
  - `applications/jellyfin/values.yaml`
  - `applications/jellyfin/values-istio.yaml`

## After apply

1. Get the dedicated gateway external IP:

```bash
kubectl -n jellyfin get svc jellyfin-gw-istio
```

2. Set local DNS or hosts entry (LAN clients):

```text
<EXTERNAL-IP> jellyfin.itosbl.com
```

3. Validate:

```bash
curl --resolve jellyfin.itosbl.com:443:<EXTERNAL-IP> https://jellyfin.itosbl.com -vk
```
