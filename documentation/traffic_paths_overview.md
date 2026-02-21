# Traffic Paths Overview

```mermaid
flowchart LR
    U[Browser or curl with Host www.itosbl.com] --> DNS[DNS or --resolve]
    DNS --> IP[192.168.1.241]

    subgraph A[Path A: simple_app_1.yaml applied]
      IP --> LB1[Service type LoadBalancer<br/>demo-web]
      LB1 --> POD1[demo-web Pod<br/>nginx]
      POD1 --> OK1[Site appears reachable]
    end

    subgraph B[Path B: Istio Gateway path]
      IP --> GW[Istio Gateway app-gw<br/>listeners :80 and :443]
      GW --> HR{HTTPRoute hostname match?}
      HR -->|matches itosbl.com or www.itosbl.com| ECHO[echo Service]
      ECHO --> OK2[Response from echo app]
      HR -->|no matching hostname| MISS[No route or default response]

      GW --> TLS{TLS cert covers hostname?}
      TLS -->|yes| HTTPSOK[HTTPS succeeds]
      TLS -->|no| HTTPSFAIL[TLS warning or failure]
    end
```

## Notes

- Applying `simple_app_1.yaml` creates a direct public entrypoint (`LoadBalancer`), so access can work even if Istio route/cert is incomplete.
- Istio path requires both route hostname match and certificate coverage for HTTPS.
