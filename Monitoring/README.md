MONITORING
----------

# Install using Helm

## Add helm repo

`helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`

## Update helm repo

`helm repo update`

## Install helm 

`helm install my-kube-prometheus-stack prometheus-community/kube-prometheus-stack`

## Expose Prometheus and Grafana Service

This is required to access prometheus and grafana server using your browser.

`kubectl expose service kube-prometheus-stack-prometheus --type=LoadBalancer --target-port=9090 --name=prometheus-service-ext`

`kubectl expose service my-kube-prometheus-stack-grafana --type=LoadBalancer --name=grafana-server-ext`

## Installation of loki from values.yaml

 `helm install --values values.yaml loki grafana/loki-stack`