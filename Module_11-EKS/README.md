# EKS

## Overview

There are multiple container orchestration tools: ECS, Kubernetes, Nomad, Docker Swarm, Mesos.

Container services on AWS:
 - EKS
 - ECS

ECS
- Control plane is managed by AWS
- Compute fleet composed of EC2 instances. They need Container runtime and ECS Agent in order to communicate with ECS control plane. You still need to manage the infrastructure\
- Or use AWS Fargate - serverless solution where AWS will manage the worker nodes. Pay only for what you use. Easily scale up or down.

EKS
- Control plane managed by AWS
- Worker nodes communicate with Control plane via k8s worker processes
- better to use because k8s is open-source and has a huge community (usage of Helm charts)
- offers High Availability - Control plane nodes are place in different AZs

## Project 1

**Create AWS EKS Cluster with a Node Group**

EKS - managed container service to run an scale K8s applications.\
EKS deploys and manages the Control plane nodes in different AZs for High Availability.

Host the Worker nodes - on EC2 - you need to manage infrastructure of the worker nodes\
                      - on Nodegroup - semi-managed, creates, deletes EC2 for you, but you need to configure it\
                      - Fargate - fully managed Worker nodes

1. Create AWS EKS IAM Role

Assign role to the EKS cluster managed by AWS to allow AWS to create and manage components on our behalf.

EKS Cluster usecase with - `AmazonEKSClusterPolicy` policy.

2. Create VPC for EKS Worker Node

Worker Nodes need specific Firewall configurations for Control Plane-Worker communication because Control plane nodes are in AWS managed account and Worker nodes in my account. Best practice configuration is Public and Private subnets.

Use CloudFormation template: https://docs.aws.amazon.com/codebuild/latest/userguide/cloudformation-vpc-template.html

3. Create EKS Cluster 

4. Connect to EKS cluster with kubectl from local machine

You need a kubeconfig file in order to communicate with k8s cluster./
`aws eks update-kubeconfig --name eks-cluster-name` - adds the info to ./kube/config necessarely for kubectl to communicate with eks cluster./

5. Create Node groups and attach worker nodes k8s

Kubelet - main k8s process on Worker nodes which communicate with other AWS services, schedules and manages Pods.\
It needs permissions to perform certain actions.\
Need to create an EC2 role with `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly` and `AmazonEKS_CNI_Policy` - internal network in k8s.\

Create Node group and attach the role recently created to it. 

6. Configure Auto-scaling for Worker Nodes

AWS doesn't automatically autoscale our resources. We need to configure K8s Autoscaler in our K8s cluster. If Autoscaler notices that two EC2 instances are under-utilise, will take the pods and schedule them on other Nodes and terminates the two EC2s.

Create a custom policy to allow autoscaling and attach it to the Role for Node groups. https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html

`curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml` - download the yaml file for Autoscaler\
`kubectl apply -f cluster-autoscaler-autodiscover.yaml` - deploy Autoscaler in EKS kube-system namespace

Autoscaler version needs to match cluster k8s version.

It saves costs but provisioning a new EC2 instance takes time.

7. Deploy an nginx app into cluster

`kubectl apply -f nginx-config.yml` - created the nginx service in k8s and also the cloud native load balancer in AWS

Requets will come on port 80 on AWS LoadBalancer, then will be forwarded to port 30204 on EC2 Node and then to port 80 of nginx service in k8s.

---

## Project 2

**Create EKS Cluster with Fargate profile**

- Serverless - AWS will create VMs on AWS account./
- 1 pod per VM\
- no support for Statefull apps or DaemonSets\

You can have both Fargate and Node groups as Worker nodes.

1. Create Role for Fargate ( EKS - Fargate Pod )

It's used to schedule pods on new VM.

2. Create Fargate profile

Pod selection rule - tell Fargate that a pod should be scheduled through Fargate.\
We need to provide our VPC becasue the Pods will have an IP address from our subnet IP range. (only private subnets)

In AWS specify namespace and match labels, ex `profile: fargate` and create `nginx-config-fargate.yaml`. 

--- 

## Project 3

**Create EKS Cluster with eksctl tool**

Simpler method than using the Console UI.

Cluster will be created with default params.\

1. Install the Homebrew tap

`brew tap weaveworks/tap`

2. Install eksctl

`brew install weaveworks/tap/eksctl`

3. Create cluster 

`eksctl create cluster --name negru-cluster --version 1.22 --region eu-east-1 --nodegroup-name negru-nodes --node-type t2.micro --nodes 2 --nodes-min 1 --nodes-max 3`

---

## Project 4 combined with Project 6

**Complete CI/CD Pipeline with EKS and private DockerHub registry**

1. Install kubectl and aws-iam-authenticator in the Jenkins container

2. Create deployment and service yaml for the Java app in Module_8-CICD_with_Jenkins

3. Create authentication of the k8s cluster with the private docker repo (Secret in k8s cluster)

`kubectl create secret docker-registry my-registry-key --docker-server=docker.io --docker-username=negru1andrei --docker-password=password`

4. Deploy configuration files with kubectl 

Before passing the yaml file to kubectl, you need to substitute all the env variables in the yaml files - can be done using `envsubst`. Install envsubst in Jenkins container.

`envsubst < kubernetes/deployment.yaml | kubectl apply -f -` - substitute all the env variables values in the yaml file and give that file to kubectl\
`envsubst < kubernetes/service.yaml | kubectl apply -f -`

```
stage("deploy the image") {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                APP_NAME = 'java-maven-app'
            }
            steps {
                script {
                    echo "deploying"
                    sh "envsubst < kubernetes/deployment.yaml | kubectl apply -f -"
                    sh "envsubst < kubernetes/service.yaml | kubectl apply -f -"
                }
            }
        }
```

--- 

## Project 7

**Complete CI/CD Pipeline with EKS and AWS ECR**

1. Make sure you have an EKS cluster already created. Either use Terraform or eksctl - easier than creating all the roles, nodes, vpc, etc from scratch. 

- use `eksctl create cluster --name negru-cluster --version 1.28 --region eu-central-1 --nodegroup-name negru-nodes --node-type t2.micro --nodes 2 --nodes-min 1 --nodes-max 3`.
- make sure to set correct AWS user in the current shell if you have multiple accounts. Set `export AWS_PROFILE=negruandreiuser`.

2. Install `kubectl` inside Jenkins container

- `curl -LO https://dl.k8s.io/release/v1.28.2/bin/linux/amd64/kubectl` - install v.1.28.2 on a Debian distro
- `chmod +x ./kubectl` - add execute permission
- `mv ./kubectl /usr/local/bin/kubectl`

3. Install `aws-iam-authenticator` inside Jenkins container. This is needed in order to autheticate with AWS.

- `curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64` - install aws-iam-authenticator on Debian
- `chmod +x ./aws-iam-authenticator`
- `mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator`

4. Make sure you have the kubeconfig correctly set in the Jenkins container. This is needed in order for `kubectl` to connect to the cluster.

- `scp -i ~/.ssh/aws-key-m2.pem ~/.kube/config ec2-user@3.120.209.48:/home/ec2-user/config` - copy your local kube config to the EC2 that hosts the Jenkins container
- `docker cp config 9bbe478076d4:/var/jenkins_home/.kube/` - copy the kube config on the EC2 to the Jenkins (make sure you create first .kube directory in that location in Jenkins)

5. Create AWS credentials in Jenkins UI and reference them in the pipeline

```
environment {
                AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
                APP_NAME = 'java-maven-app'
            }
``` 

6. Create ECR repo

Each repo is 1 app which can contains multiple tags

7. Authenticate to the ECR registry

`aws ecr get-login-password | docker login --username AWS --pasword-stdin registry-URL`

8. Create credentials in Jenkins for AWS name ecr-credentials

9. Create Secret for AWS ECR

`kubectl create secret docker-registry my-registry-key-ecr --docker-server=registry-URL --docker-username=AWS --docker-password=password`

10. Use the Jenkinsfile-ECR 
