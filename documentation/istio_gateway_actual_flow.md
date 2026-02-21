# Istio Gateway Actual Flow (Your Objects)

```mermaid
flowchart TB
    CLIENT[Client: browser/curl<br/>Host: www.itosbl.com] --> DNS[DNS or --resolve]
    DNS --> LBIP[Gateway external IP<br/>192.168.1.241]

    LBIP --> ISTIO_SVC[Istio ingress Service<br/>type LoadBalancer or NodePort in istio-system]
    ISTIO_SVC --> GW[Gateway<br/>namespace: gateway<br/>name: app-gw]

    GW --> LHTTP[Listener: http :80]
    GW --> LHTTPS[Listener: https :443]

    LHTTP --> R1[HTTPRoute<br/>app-route<br/>hostnames: itosbl.com, www.itosbl.com]
    LHTTP --> R2[HTTPRoute<br/>blue-route<br/>hostname: blue.itosbl.com]
    LHTTP --> R3[HTTPRoute<br/>green-route<br/>hostname: green.itosbl.com]

    R1 --> S1[Service: echo:80]
    R2 --> S2[Service: echo-blue:80]
    R3 --> S3[Service: echo-green:80]

    S1 --> P1[Deployment/Pod: echo<br/>http-echo text default]
    S2 --> P2[Deployment/Pod: echo-blue<br/>http-echo text blue]
    S3 --> P3[Deployment/Pod: echo-green<br/>http-echo text green]

    LHTTPS --> CERTS[Gateway TLS cert refs<br/>app-tls, blue-tls, green-tls]
    CERTS --> CM[cert-manager Certificate resources<br/>issued by ClusterIssuer letsencrypt-prod]
    CM --> SECRET[Secrets in namespace gateway<br/>used by Gateway TLS terminate]
```

## Match Rules

- `www.itosbl.com` must be present in `app-route.hostnames` to select backend `echo`.
- `www.itosbl.com` must be present in `Certificate app-tls dnsNames` for valid HTTPS.
