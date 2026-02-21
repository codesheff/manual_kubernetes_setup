kubectl apply -k cert-manager # kustomize!
k apply -f istio_gateway_tls.yaml 


# get the external ip of the service
kubectl -n gateway get svc app-gw-istio

# check the curl works ( this overrides www.itosbl.com:80 with the address you specify)
# if your overrisde doesn't match the url you use, then command just uses normal dns lookup
curl --resolve www.itosbl.com:80:<EXTERNAL_IP> http://www.itosbl.com