kubectl apply -k cert-manager # kustomize!
k apply -f istio_gateway_tls.yaml 


# get the external ip of the service
kubectl -n gateway get svc app-gw-istio

# check the curl works
curl --resolve www.itosbl.com:80:<EXTERNAL_IP> http://www.itosbl.com