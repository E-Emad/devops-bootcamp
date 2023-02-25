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

