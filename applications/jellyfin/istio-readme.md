# Jellyfin ingress via Istio Gateway API

This setup uses a dedicated Istio Gateway (`jellyfin/jellyfin-gw`) for `jellyfin.itosbl.com`.

For a full from-scratch workflow, use `applications/jellyfin/rebuild/README.md`.

## Files

- `istio-jellyfin-lan-gateway.yaml`
- `istio-jellyfin-local-only.yaml`
- `values-istio.yaml`

## Apply

```bash
helm upgrade --install jellyfin jellyfin/jellyfin \
	-f applications/jellyfin/values.yaml \
	-f applications/jellyfin/values-istio.yaml \
	--namespace jellyfin --create-namespace

kubectl apply -f applications/jellyfin/istio-jellyfin-lan-gateway.yaml
kubectl apply -f applications/jellyfin/istio-jellyfin-local-only.yaml
kubectl -n jellyfin patch svc jellyfin-gw-istio -p '{"spec":{"externalTrafficPolicy":"Local"}}'
```

## Verify

```bash
kubectl -n jellyfin get gateway jellyfin-gw
kubectl -n jellyfin get httproute jellyfin-route -o wide
kubectl -n jellyfin get certificate jellyfin-tls
kubectl -n jellyfin get secret jellyfin-tls
kubectl -n jellyfin get svc jellyfin-gw-istio
```

## Test (replace with your Istio external IP)

```bash
curl --resolve jellyfin.itosbl.com:80:<JELLYFIN_GW_EXTERNAL_IP> http://jellyfin.itosbl.com
curl --resolve jellyfin.itosbl.com:443:<JELLYFIN_GW_EXTERNAL_IP> https://jellyfin.itosbl.com -vk
```

## Important

- This route uses host `jellyfin.itosbl.com`; change it in `istio-jellyfin-lan-gateway.yaml` if needed.
- If you want to use only Istio (not Traefik) for Jellyfin, set `ingress.enabled: false` in `applications/jellyfin/values.yaml` and run `helm upgrade`.
- The dedicated gateway avoids affecting other hosts/routes that use a shared ingress gateway.

## LAN-only recommendation

Use a dedicated gateway for Jellyfin so LAN restrictions do not impact other hosts on `app-gw`.

1. Disable Traefik ingress for Jellyfin:

```bash
helm upgrade --install jellyfin jellyfin/jellyfin \
	-f applications/jellyfin/values.yaml \
	-f applications/jellyfin/values-istio.yaml \
	--namespace jellyfin
```

2. Apply dedicated Jellyfin gateway and route:

```bash
kubectl apply -f applications/jellyfin/istio-jellyfin-lan-gateway.yaml
```

3. Keep Jellyfin service internal (`ClusterIP`) and route only through dedicated Istio `jellyfin-gw`.

4. Apply `istio-jellyfin-local-only.yaml` to allow only LAN clients (`ipBlocks: 192.168.1.0/24`) on `jellyfin-gw`.

5. Ensure gateway source IP is preserved, otherwise all traffic may appear as cluster/node IP and be denied:

```bash
kubectl -n jellyfin patch svc jellyfin-gw-istio -p '{"spec":{"externalTrafficPolicy":"Local"}}'
```

6. Point local DNS/split-horizon DNS `jellyfin.itosbl.com` to the dedicated gateway IP:

```bash
kubectl -n jellyfin get svc jellyfin-gw-istio
```

7. Remove internet port-forwards for Jellyfin gateway IP if you want strict LAN-only access.

8. Optional cleanup if you were previously using shared `app-gw` for Jellyfin:

```bash
kubectl -n gateway delete httproute jellyfin-route --ignore-not-found
kubectl -n gateway delete certificate jellyfin-tls --ignore-not-found
```
