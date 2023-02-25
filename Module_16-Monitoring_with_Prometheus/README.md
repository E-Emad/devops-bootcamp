# Monitoring with Prometheus 

Prometheus - monitoring tool for highly dynamic container environments. Alert the sys admins responsible for infrastructure if something goes wrong.\

**Prometheus Architecture**

Storage - time series database that stores metric data\
Data retrieval worker - pull metrics from services, apps, etc and store in the db\
Webserver - query the db using PromQL and used to display data in some data visualization tool like Grafana\

3 Metric types - Counter - how many exceptions had the app
               - Gauge - metric that can go up and down, like CPU usage
               - Histogram - how long or how big something was

In order to retreive the metrics, the target host have to expose metrics at `hostname/metrics` endpoint and the format to be one that Prometheus understands.

Exporter - another process that collects the metrics of a target and convert them in format that Prometheus understands. Expose its own /metrics endpoint for Prometheus to scrape. Exporters also available as Docker images. 

To monitor own application (ex. how many requests, or how many exceptions) you need a client library for that specific programming language. 

Other monitoring tools like New Relic or Amazon Cloudwatch requires the app to push the metrics to a centralized location - this can create a lot of network traffic and can becom a bottleneck. On the other hand, Prometheus needs a scraping endpoint and it will scrape the data. 

Prometheus expose it's own /metrics endpoint to monitor Prometheus server. 

Alertmanager - responsible for firing the alerts to different channels: Slack, Email.

Integrates very well with Kubernetes, offering monitoring of the k8s cluster nodes out-of-the box.

**How to deploy Prometheus in K8s cluster?**

- create every configuration file, stateful sets, config maps, etc
- using an operator - manager of the Prometheus components
- using helm chart to deploy the operator - most prefered way




## Project 1 

**Install Prometheus stack in K8s cluster**

1. `eksctl create cluster --name online-shop --node-type t3.medium --nodes 2` - will createa a k8s cluster with two nodes of t3.medium type

2. Add the helm repo where the Prometheus is located using: `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`. 

3. Deploy microservices in the cluster using: `kubectl apply -f microservices.yaml`

4. Create monitoring namespace with `kubectl create namespace monitoring`

5. Install the chart using Helm: `helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring`

6. `kubectl get all -n monitoring` - see everything that has been deployed in the monitoring namespace


`statefulset.apps/prometheus-monitoring-kube-prometheus-prometheus` - Prometheus server which is managed by Operator\
`deployment.apps/monitoring-kube-state-metrics` - own Helm chart - it scrapes K8s components itself and makes them available for Prometheus\ 
`daemonset.apps/monitoring-prometheus-node-exporter` - run on every worker node of K8s. It connects to the server and translate server metrics (CPU, etc) for Prometheus to understand

ConfigMaps and Secrets are also managed by the Operator.

CRDs - extension of K8s API - custom resource definitions

7. `kubectl port-forward service/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring &` - PrometheusUI (process running in the background)

8. `kubectl port-forward service/monitoring-grafana 8080:80 -n monitoring &` - Grafana (admin / prom-operator)

---

## Project 2

****