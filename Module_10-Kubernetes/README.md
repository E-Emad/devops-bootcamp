# Kubernetes module

## Overview

- Kubernetes is the mostly used container orchestation tool.
- It offers: high availability, automatic scaling, disaster recovery and self-healing.

**Pods**

- the smallest unit of k8s
- abstraction over container 
- tipically 1 pod contains 1 container
- ephemeral 
- new IP address is assign on re-creation

**Service**

- static IP for the pods
- lifecycle of the pods and service are not connected
- load balancer between pods
- could be internal (database) or external (app accessed through browser)
- Ingress is the only entrypoint in your cluster, it forwards traffic to service

1. Cluster IP type 

- internal service 
- pods are identified via selector 
- all the labels should be matched 
- when service is created, enpoints object is also created (keep track of which pods are enpoints of the service)
- when you have multiple ports open in a service, you have to name the ports in the yaml

2. Headless service type

- use case: statefull apps, where one pods needs to communicate directly with another specific pod
- setting `clusterIP: None` in the service configuration -> will return the IPs of the Pods, not the IP of the service

3. NodePort service type

- service can be of 3 types: `type: ClusterIP`, `type: NodePort` and `type: LoadBalancer`. ClusterIP is by default if not specified in the config.
- NodePort creates a static port on each Node in the cluster. That makes external traffic open from outside on every Node (range: 30000-32767)
- ClusterIP service is atomatically created

4. LoadBalancer service type

- service becomes accesible externaly through a cloud platform loadbalancer
- NodePort and ClusterIP service is created automatically

**ConfigMap**

- stores non-confidential data in key-value pairs
- external configuration for your application 
- it is a local volume type which can store individual key-value pairs which are passed as env variables to the app/pods or you can store a file which can be mounted inside the container (use case: config file used by the app)

**Secrets**

- same as ConfigMap, but used for sesitive data
- base64 encoded
- Secrets and ConfigMaps can be used inside the application as env variables or mounted as a properties file

**Volumes**

- used to persist data if a pod dies (could be local or outside of k8s cluster)
- volumes are mounted to every pod & when a pod dies, data is persisted in a volume

**Deployment**

- abstraction over pods
- it does not depened on previous data (also called stateless)

**StatefulSet**

- blueprint for stateful app (ex. database)
- it makes sure that data reads and writes are synchronized to avoid data inconsistencies
- it maintains a sticky identity for each of their pods
- pods are not interchangeable
- pods can't be created/deleted at the same time
- name of the pod in composed of $(statefulset name)-$(oridnal)

Scaling DB apps:
- only 1 replica can make changes
- each replica has it's own storage and those are constantly synchronized

Deploying StatefulSets are not easy, so a simpler solution would be to host all the stateless applications inside the k8s cluster and have separate DBs outside of k8s cluster.

**Namespace**

- used to organize resources inside a "virtual cluster"
- kube-system - master processes 
- kube-public - public info about the cluster
- kube-node-lease - heartbeat of nodes - determine the availability of nodes
- defult namespace - where you create resources by default
- specify namespace key in metadata of any resource you create
- each NS must define own ConfigMap, Secret
- service can be accessed on another NS
- not namespaced components: volume and node 

Use cases: 

- Resources grouped in ns. For ex: Database ns, Monitoring ns, Elastic stack ns, Nginx-ingress ns
- Conflicts:  many teams, same application name -> using only one namespace, one team will override components from the other team. 
- Resource sharing: dev and staging ns -> both will use resources from nginx-ingress controller ns nad Elastic Stack ns. 
- Blue/ green deployment 
- Access and resource limits on namespaces - each team has own isolated environment and limits on each namespace in terms of CPU and Memory.

You can use `kubens` to change the active namespace, and not use -n with every kubectl command.

**Ingress component**

- used to forward external traffic to the k8s cluster componenets, internal services.
- Ingress component just defines the rules of redirection and Ingress Controller (pod) evaluates those rules and makes the actual forwardin.
- Ingress controller is the entrypoint to the cluster. Many 3rd party implementations, for example: k8s nginx ingress controller
- each Ingress object configures one domain (or 1 domain and multiple subdomains of that domain). If you want 2 domains, you need 2 ingress objects. 
- to configure https, you need a Secret containing a tls certificate


---

## Authentication and Authorization in k8s

- K8s doesn't manage Users natively.
- Admins can choose from different authenticationstrategies.
- K8s supports multiple authorization modules, suchas ABAC mode, RBAC Mode and Webhook mode

API server handles authentication of all the requests. 

Available authentication strategies: Client certificates, Static token file, 3rd party identity service, like LDAP.

Security best practice - Least Privileage access. Admins needs cluster wide permissions while developers only limited permissions for example to deploy app to 1 namespace.

RBAC = Role-based access control - A method of regulating access to resources based on the roles of users within the organization.\
Enable RBAC: kube-apiserver --authorization-mode=RBAC --other-options\
4 kinds of K8s resources: - ClusterRole, Role - rules that represent a set of permissions\
                          - ClusterRoleBinding, RoleBinding - link/bind a Role or ClusterRole to a User or Group

ServiceAccounts provide an identity for processesthat run in a Pod, for example Jenkins or Prometheus. A RoleBinding or ClusterRoleBinding can link a role to a Service Account.
 
---

## Kubernetes architecture

Nodes - multiple VMs or physical servers

Master node (Control plane) - manages Worker Nodes and pods in the cluster, it needs to be replicated across different machines

Worker node - containerized apps run on this. It needs much more compute resources than the Master node

Every Worker node needs 3 processes to be installed:\
    - container runtime (cri-o, docker, containerd - very lightweight)\
    - kubelet - agent that makes sure containers are running in pods, talks to server to get resources available\
    - kube-proxy - network proxy with intelligent forwarding of requests to the pods\
                 - enforce (where possible) pods to talk to each other on the same Node to avoid network overhead 

Every Master node has 4 processes:\
    - API Server - single entrypoint to the cluster (kubectl talks to API Server) and is the gatekeeper for authtentication, validating the requests\
    - Scheduler - just decides on which Node the new pod should be scheduled. It takes into considerations resource requirements, hardware/software/policy constraints, data locality - kubelet executes the request coming from the Scheduler\
    - Controller manager - Detects state changes, like crashing of Pods and tries to recover the cluster state as soon as possible. It talks to the scheduler\
    - etcd - store for all cluster data\
           - all cluster changes are stored here\

As the cluster grows, you have to add more Worker and Master nodes.

Minikube - running as a docker container or as a VM to create a cluster (including all processes from Worker and Master nodes on one server)

## CLI commands

```
install hyperkit and minikube
brew update
brew install hyperkit
brew install minikube
kubectl
minikube

create minikube cluster
minikube start --vm-driver=hyperkit
kubectl get nodes
minikube status
kubectl version

delete cluster and restart in debug mode
minikube delete
minikube start --vm-driver=hyperkit --v=7 --alsologtostderr
minikube status

kubectl commands
kubectl get nodes
kubectl get pod
kubectl get services
kubectl create deployment nginx-depl --image=nginx
kubectl get deployment
kubectl get replicaset
kubectl edit deployment nginx-depl

debugging
kubectl logs {pod-name}
kubectl exec -it {pod-name} -- bin/bash

create mongo deployment
kubectl create deployment mongo-depl --image=mongo
kubectl logs mongo-depl-{pod-name}
kubectl describe pod mongo-depl-{pod-name}

delete deplyoment
kubectl delete deployment mongo-depl
kubectl delete deployment nginx-depl

create or edit config file
vim nginx-deployment.yaml
kubectl apply -f nginx-deployment.yaml
kubectl get pod
kubectl get deployment

delete with config
kubectl delete -f nginx-deployment.yaml
#Metrics
kubectl top The kubectl top command returns current CPU and memory usage for a cluster’s pods or nodes, or for a particular pod or node if specified.
```

## Persisting data in Kubernetes using volumes

- Persistent volume - provisioned by admin or dynamically using Storage class\
                    - not namespaced\
                    - local volume types violate the 2 principals of data persistency: - being tied to 1 specific node and not surviving in case of cluster crash
- Persistent volume claim - a request for storage by a user
- Storage class - provisions PV dynamically only when PVC claims it (kinda on demand storage)\
                - pod claims storage via PVC which requests storge from Storage class which creates a PV that meets the needs of the claim


## Project 1

**Deploy MongoDB and Mongo Express into local k8s cluster**

1. Install minikube (k8s cluster on your local machine - master and worker processes running on a single node)

`minikube start --driver=docker` - start minkube cluster as a docker container
- kubectl is installed with minikube 

2. Create mongodb deployment yaml file

MongoDB needs two env variables: MONGO_INITDB_ROOT_USERNAME and MONGO_INITDB_ROOT_PASSWORD. Values for those have to be stored in a Secret config file in a base64 encoded format. To encode this, you can use `echo -n "andreinegru" | base64` to get the econded values. (-n option is used to omit echoing trailing newline)

Becasue you reference values from Secret, you have to creat the Secret prior to the deployment. 

`kubectl get pods -o wide` - show more info about the pods (like IP, node)

3. Create mongodb internal service yaml file

Service and Deployment usually lives in the same yaml file.

4. Create mongo espress deployment 

It needs ME_CONFIG_MONGODB_ADMINUSERNAME and ME_CONFIG_MONGODB_ADMINPASSWORD set as env variables in order to connect to mongo db and ME_CONFIG_MONGODB_SERVER which is the MongoDB container name, but since we use pods and services, it will be the name of the mongodb service. We can store this in a ConfigMap since is not sensitive data.

5. Create mongo express service 

This have to be created as a loadbalancer (external service) in order to access it from the browser.

Use `minikube service <mongo-express-service>` to assign an external IP to the Mongo Express service in order to access it via browser.

---

## Project 2

***Deploy Mosquitto message broker using ConfigMap and Secret Volume types**

1. Create Mosquitto ConfigMap with the `mosquitto.conf` file and the content of the file beginning with |

2. Create Mosquitto Secret with the `secret.file` file and the content of the file beginning with | (content must be base64 encoded)

3. Create Mosquitto deployment

Use `eclipse-mosquitto:1.6.2` image to build the container and specify wich volumes can be mounted inside the containers.\
Inside the container mount the volumes under the `volumeMounts:`.

4. Enter the mosquitto contianer and validate the files are there

Use `kubectl exec -it mosquitto-5887d7ffcb-s6nct -- /bin/sh` to get inside the container in the pod.

---

## Project 3

**Deploy a Stateful app (MongoDB) using Helm**

When you want to create a K8s cluster in Cloud is better to choose a managed one, becasue you care only about the worker nodes, use cloud native load balancer for ingress controller and use the cloud storage. Examples of Cloud providers: AWS, Azure, Google, Linode.

Helm is a package manager for K8s. It packages  YAML files and distributes them in public and private repositories.\
Helm Charts contains:
- description of Helm package in Chart.yaml
- 1 or more templates that contains yaml manifests for k8s\

Use existing oficial charts ex: MySQL or Elasticsearch

Helm Chart structure:
- top level mychart folder = name of the chart\
    - Chart.yaml = metadata about chart
    - values.yaml = values for the template files
    - charts folders = chart dependencies
    - templates folder = acutal template files

Use case - Deploy the same bundle of K8s YAML files across multiple clusters (Dev, Stage, Prod). 

1. Created K8s cluster on Linode Kubernetes Engine

To work with the cluster and execute kubectl commands egainst it you have to set env variable KUBECONFIG=kubeconfig.yaml

2. Deploy replicated MongoDB (StatefulSet using Helm Chart) and configured Data Persistence with Linode Block Storage

`helm repo add bitnami https://charts.bitnami.com/bitnami` - add the repo\
`helm search repo bitnami` - see all charts in this repo\
Charts provide default values which you can override.\

`helm install mongodbmyname --values mongo-override-chart.yaml bitnami/mongodb` - mongodbmyname is the stateful set name\
`kubectl get all` - get every resource pods, services, deployments, etc\

3. Deploy MongoExpress (Deployment and Service)

We can create our own config file, no need for a Chart.

`kubectl apply -f mongo-express-helm-project.yaml` - create mongo-express deployment

4. Deploy NGINX Ingress Controller as Loadbalancer (using Helm Chart)

`helm repo add nginx-stable https://helm.nginx.com/stable` - add repo\
`helm install my-release nginx-stable/nginx-ingress` - install the chart\
Ingress controller will be added to our cluster and also the LoadBalancer will be created in the Linode Cloud.\
LoadBalancer forward to Ingress controller which will than forward based on the ingress rules configured.

Ingress controller service will have external IP of the Linode LoadBalancer.

5. Configure Ingress rules

`kubectl apply -f mongo-express-linode-ingress.yaml` - apply ingress rules

`kubectl scale --replicas=0 statefulset/mongodbmyname` - delete all the mongodb pods => volumes in Linode will be unattached

`kubectl scale --replicas=3 statefulset/mongodbmyname` - observe the data persistance 

---

## Project 4

**Deploy web app in a k8s cluster from a private Docker registry**

When pulling from private registry you need to offer k8s explicit access.

1. SSH into minikube VM and login to the DockerHub private repo from there

`ssh minikube`\ 
`docker login --username usernamedockerhub --password passworddockerhub` - login to DockerHub repo -> .docker/config.json is created

2. Create Secret component in k8s

`docker-secret-private-repo.yaml` - Secret k8s component - key .dockerconfigjson will contain base64 encoded value of the .docker/config.json file\
To use kubectl outside of Minikube, you need first to copy the .docker/json from minikube into local machine using `scp -i $(minikube ssh-key) docker@$(minikube ip):.docker/config.json .docker/config.json`.\

`cat .docker/config.json | base64` - encode the .docker/config.json, copy the value and put into secret yaml file\
`kubectl create secret generic my-registry-key --from-file=.dockerconfigjson=.docker/config.json --type=kubernetes.io/dockerconfigjson` - creates the secret

3. Create the deployment for the app

`kubectl apply -f docker-demo-app-deployment.yaml` 

---

## Project 5

**Setup Prometheus monitoring in K8s cluster**

Stateful applications need constant management and syncing after deployment. So stateful applications, like database need to be operated. Instead of a human operator, you have an automated scripted operator. Operators are createdby official maintainers.

How it works:
- control loop mechanism
- make use of CRDs (Custom Resource Definitions - custom k8s component which extends the k8s api)

1. Install Prometheus operator using Helm 

`helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`\
`helm repo update`\
`helm install [RELEASE_NAME] prometheus-community/kube-prometheus-stack`

To access Grafana: `kubectl port-forward deployment/prometheus-grafana 3000` => can be accessed then on localhost:3000

---

## Project 6

**Deploy microservices app (Online shop) with Production & security best practices**

Microservices - small independent services

Communication between microservices can happen in different ways: - Service to Service API calls\
                                                                  - message-based (through a message broker)\
                                                                  - Service mesh architecture (Platform layer on top of theinfrastructure layer,like Istio,Linkerd,\ HashiCorp Consul)

Info you need to know when deploying microservices into a k8s cluster: 
- Which services you need to deploy?
- Which service is talking to which service?
- How are they communicating?
- Which database are they using?
- 3rdparty services
- On which port does each service run?

The order when deploying an app composed of multiple microservices:\
    1. Deploy any 3rd party apps\
    2. Create Secret and ConfigMap components\
    3. Create deployment and Service for each microservice

Note: When deploying multiple similar services to K8s, you can use helm chart with 1 common template and replace specific values for each service on the fly during deployment. 

1. Find the manifests of the online shop (deployment and service) here: https://github.com/nanuchi/microservices-demo/blob/master/release/kubernetes-manifests.yaml

2. Create `Module_10-Kubernetes/microservices/config-best-practices.yaml` containing Deployment and Service for all microservices

3. Create a cluster on EKS:

- `eksctl create cluster --name negru-cluster-best-practice --version 1.28 --region eu-central-1 --nodegroup-name negru-nodes --node-type t3.medium --nodes 7 --nodes-min 5 --nodes-max 15`
- kubeconfig is automatically updated when creating the cluster with eksctl

4. Create a namespace using `kubectl create namespace myapp`

5. Apply the manifest containing microservices in that namespace

- `kubectl apply -f Module_10-Kubernetes/microservices/config-best-practices.yaml -n myapp`

6. Make sure the frontend service is of `type: LoadBalancer`. If you deployed on EKS, a Cloud native load balancer will be provisioned by AWS, being the single entrypoint to our cluster from external sources. Also you can map that ALB to a Route53 to have a nice domain name accessible. 


Deploy using best practices: 

- Specify a pinned version on each container image - Otherwise, latest version is fetched, which makes it unpredictable and intransparent as to which versions are deployed in the cluster
- Configure a liveness probe on each container - K8s knows the Pod state, not the application state. Sometimes pod is running, but container inside crashed. With liveness probe we can let K8s know when it needs to restart the container
- Configure a readiness probe on each container - Let's K8s know if application is ready to receive traffic
- Configure resource limits & requests for each container - To make sure 1 buggy container doesn't eat up all resources, breaking the cluster
- Don't use NodePort in production - security issue since it one port on all the Worker nodes; Ingress or LoadBalancer are the alternetives
- Always deploy more than 1 replica for for each application - To make sure your application is always available, no downtime for users!
- Always have more than 1 Worker Node - avoid single point of failure
- Label all your K8s resources - Have an identifier for your components to group pods and reference in Service
- Use namespaces to group your resources
- Ensure Images are free of vulnerabilities 
- No root access for containers - With root access they have access to host-level resources. Much more damage possible, if container gets hacked

---

## Project 7 

**Create Helm chart for Microservices**

Helm Chart - reusable k8s configuration

I'll create 1 shared Helm chart for all the services because they are more or less the same. 

1. Create microservice and redis Helm Chart and values for them

`helm create microservice` - create microservice Helm Chart
`helm create redis` - create redis Helm Chart 

Put both into charts/ forlder. 

`values.yaml` - default values for the chart

I'll have values/ folder wich will contain all the values yaml file for each microservice.

`helm template -f email-service-values.yaml emailservice` - just gives a preview of the template filled in with the values\
`helm lint -f email-service-values.yaml microservice` - examines a chart for possible issues\

2. Deploy a microservice

`helm install -f email-service-values.yaml emailservice microservice`\
                                          (release name) (chart name)\

3. Make script to deploy all the microservices using `helm install` for each microservice                                        


## Project 8 

**Deploy microservices with Helmfile**

The better option to deploy when working with multiple charts is using a Helmfile, which is a declarative way to configure your k8s cluster.


`brew install helmfile`\
`helmfile synch` - deploy the apps in the helmfile\
`helmfile destroy` - remove all the helm installations and remove pods/resources\




