# Terraform IaC

Declarative = define END result and Terraform will figure it how to do that

**Terraform vs Ansible**

- Terraform is a mainly infrastructure provisioning tool 
- Ansible - configuration management tool

Terraform needs to inputs: desired state (config file) and state file (tracks your real infrastructure in a state file). Based on the config file and state file, TF creates an execution plan. Next, TF executes the changes to the infrastructure and updates the state file.

Terraform providers - responsible for understanding the API of that platform (ex. AWS)

Resource - used to create new resources\
Data source - to query an existing resource

**How to use variables ?**
- First you define the variable in config file and then set the variable when applying the config
- You can set variable interactively, setting it as a CLI option (`terraform apply -var "subnet_cidr=10.0.30.0/24"` or in a variable file `terraform-dev.tfvars`).
- Another usecase would be having 3 different `.tfvars` files for `prod`, `dev` and `test` and a single config file with the infrastructure.

**Environment variables**
- AWS Env Vars: Set AWS credentials for AWS provider as environment variable. Example: `export AWS_ACCESS_KEY_ID="acceskey"`
- TF-Env Vars: TF has env vars, which you can use to change some of TF's default behavior, for example enabling detailed logs. Example: `export TF_LOG=on`
- Define your own custom env variables for example: `export TF_VAR_avail_zone="eu-east-1a"` and define `variable avail_zone {}` in terraform config.

Terraform is an Infrastructure as Code tool, that's why you can host the config files in a separate git repo. 

If you need to execute commands/scripts on virtual servers you can use `user_data` which most of the cloud providers have or using Terraform Provisioners (Can be used to execute commands on the local machine or remote machine to prepare the infrastructure).

- "remote-exec" provisioner - invokes script on remote machine after the resource is created. Params "inline" - list of commands and "script" - path to script
- "file" provisioner - copy files or directories from local machine to the remote machine
- "local-exec" provisioner - ivokes a local script on the local machine once the resource is created

Although provisioners are available, they are not recommended because it breaks the idempotency concept (applying a config multiple times, will produce the same output, for example if you apply a terraform config 10 times, without changing the config, terraform will create the infrastructure just oance) and also Terraform does not know what you executed and if it suceeded or not. As an alternative, you can use configuration management tools like Ansible. 

**Modules**

A module is a container for multiple resources that are used together.
- Organize and group configurations
- Encapsulate into distinct logical components
- Reuse
- Without modules, complex configurations in a huge file with no overview
- you can easily reuse same configuration, e.g. EC2 instance for different AWS regions
- You can customize the configuration withvariables
- And expose created resources or specificattributes with output values
- There are many available on TF registry

An example could be a module for EC2 instance with configured networking and permissions.

`terraform init` - initialize Terraform - this is needed when defining a new module or provider\
`terraform plan` - preview Terraform actions\
`terraform apply -var-file terraform-dev.tfvars` - apply configuration with variables file\
`terraform destroy -target aws_vpc.myapp-vpc` - destroy a single resource BUT it's better to delete the resource from config and apply again\
`terraform destroy` - destroy everything\
`terraform state list` - show resources from current state\
`terraform state show aws_vpc.myapp-vpc` - show current sate of a resource\


## Project 1 

**Automate AWS Infrastructure**

If using multiple AWS accounts, use env variable `AWS_PROFILE` in the shell to set the one you want to use.

1. Create VPC and Subnet 

2. Created custom Route Table

3. Added Subnet Association with Route Table

4. Created Security Group

5. Created EC2 Instance (Fetch AMI, Create ssh key-pair and download .pem file and restrict permission)

6. Configured ssh key pair in Terraform config file

7. Created EC2 Instance

8. Configured Terraform to install Docker and run nginx image

Best practices:
- Create own VPC and leave the defaults created by AWS as is
- Security:  Store your .pem file ssh private key in .ssh folder. Restrict permission (only read for our User) on .pem file
- Security: Don’t hardcode public_key in Terraform config file!


---

## Project 2

**Deploy EKS cluster**

1. Created the VPC by using the VPC module

2. Created the EKS cluster and worker nodes by using the EKS module

3. Configured Kubernetes provider to authenticate with K8s cluster

4. Deployed nginx Application/Pod

--- 

## Project 3
