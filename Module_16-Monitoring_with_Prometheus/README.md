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

**Create Alert Rules for the application**

Because we are using Prometheus Operator deployed in the K8s stack, we can define the Alert Rules as CRDs and Operator will tell the Prometheus to add the new rules to it's configuration and reload the alert configuration. Otherwise, we would need to edit the configuration file of the Prometheus server itself. 

1. Create `alert-rules.yaml` containing 2 rules. 

2. Apply the CRDs in the monitoring namespace 

3. Prmoetheus hand over to Alert manager the firing alert

4. Configure Alertmanager to send Email 

- which alert to which receiver ?
- create CRD for Alertmanager - `alertmanager-config.yaml` and apply the changes
- create `email-secret.yaml` which will have the password of the email with name `gmail-auth-secret` and data with key `password` and value of the password base64 encoded.
- enable allow less secure apps on Gmail in order to send an email programatically 
- under the route, we specify using matchers the name of the alerts and to which receiver to be sent

5. Apply configurations

- `kubectl apply -f email-secret.yaml`
- `kubectl apply -f alertmanager-config.yaml`

Alert manager config is automatically picked up by the Alert Manager application

---

## Project 3

**Configure monitoring for a Third-party Application**

We can monitor Redis for different metrics (under load, too many connections, redis instance is down, etc). We have to use Prometheus Exporter - which is an app that \ connects to the Redis service and translates those metrics in a time-series data and will expose to /metrics endpoint where Prometheus will scrape that. Custom k8s \ resource must be deployed together with the exporter - called ServiceMonitor 

1. Deploy Redis Exporter

- use Helm Chart - which has everything we need configured inside
- https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-redis-exporter
- `redis-values.yaml` - used to override the default values of the Redis Exporter Chart - we need `release: monitoring` in order to link the ServiceMonitor with Prometheus
- Prometheus Rules can be configured in the Chart, but because we can modify them multiple times, it's better to create them separately 

- `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
- `helm repo update`
- `helm install redis-exporter prometheus-community/prometheus-redis-exporter -f redis-values.yaml`

2. Configure Alert Rules - when Redis is down or it has to many connections 

- `https://samber.github.io/awesome-prometheus-alerts/rules#redis` - Rules already made for a lot of services
- `kubectl apply -f redis-rules.yaml` - in default namespace

3. Create Redis Dashboard

- Use existing Redis Dashboard - https://grafana.com/grafana/dashboards/763-redis-dashboard-for-prometheus-redis-exporter-1-x/

---

## Project 4

**Configure monitoring for own application**

- we have to define the metrics
- use Prometheus Client Librariers in the application we want to monitor - one for each programming language

1. Expose metrics for a Nodejs app

- expose 2 metrics: Number of requests and duration of them

2. Build Docker image for the Nodejs app

- `docker build -t negru1andrei/demo-monitoring:nodeapp .`
- `docker login`

3. Push to repo

- `docker push negru1andrei/demo-monitoring:nodeapp`

4. Deploy app into k8s cluster

- `k8s-config.yaml` used to deploy into cluster
- `kubectl apply -f k8s-config.yaml`

5. Create a ServiceMonitor that points to /metrics

- `kubectl apply -f k8s-config.yaml` 

6. Visualize data inside Grafana

- `rate(http_request_operations_total[2])` - requests/s 
- `rate(http_request_duration_seconds_sum[2])` - duration of the requests