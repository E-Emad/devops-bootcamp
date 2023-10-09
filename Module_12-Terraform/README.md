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

**Automate AWS Infrastructure - Provision EC2 and deploy Nginx container**

If using multiple AWS accounts, use env variable `AWS_PROFILE` in the shell to set the one you want to use.\
Use `terraform fmt` to automatically format terraform files. 

1. Create VPC and 1 Subnet in one AZ

- changing the AZ of the subnet, the subnet will be destroyed then re-created
- NACL to subnet level - everything is open by default
- SG to ec2 level - everything is closed by default
- when creating a VPC, a route table is created by default but as a best practice, create new components, don't use the default ones

```
resource "aws_vpc" "myapp_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp_subnet_1" {
  vpc_id     = aws_vpc.myapp_vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone

  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}
```

2. Created custom Route Table & Internet Gateway

```
resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_route_table" "myapp_rtb" {
  vpc_id = aws_vpc.myapp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}
```

3. Added Subnet Association with Route Table

- by default, the subnet is associated with the Main route table of the VPC. You have to explicitly associate the new route table created to the subnet.

```
resource "aws_route_table_association" "rtb_subnet_association" {
    route_table_id = aws_route_table.myapp_rtb.id
    subnet_id = aws_subnet.myapp_subnet_1.id
}
```

4. Created Security Group

- allow incoming traffic on port 22 and 8080 
- allow everything on the egress (traffic leaving the server) 
- default security group is created when creating a VPC, you can use the default one, or create a new SG

```
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
```
- this can be used to automatically detect the ip address of your laptop, just keep in mind the apply again the configuration when changing the network

```
resource "aws_security_group" "myapp_sg" {
  name   = "myapp_sg"
  vpc_id = aws_vpc.myapp_vpc.id

  ingress {
    description      = "ssh on port 22"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "http on port 8080"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}
```

5. Created EC2 Instance (Fetch AMI, Create ssh key-pair and download .pem file and restrict permission)

- ami must be dynamically specified
- changing the subnet id of an instance, will force the re-creation of that instance and place it to corresponding subnet
- specifying `associate_public_ip_address = true` after creation, forces the re-creation of the instance

6. Configured ssh key pair in Terraform config file

```
resource "aws_key_pair" "myapp_key_pair" {
    key_name   = "${var.env_prefix}-key"
    public_key = file(var.key_location)
}
```

- if you update the public_key, the Terraform won't automatically recreate the ec2 server associated with the public key. You have to destroy it and recreate the instance by yourself. This can cause downtime. 
- `terraform destroy -target=aws_instance.myapp_server` can be used to destroy the ec2 server

7. Created EC2 Instance

```
resource "aws_instance" "myapp_server" {
  ami                    = data.aws_ami.amzn_linux_2023_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.myapp_subnet_1.id
  vpc_security_group_ids = [aws_security_group.myapp_sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.myapp_key_pair.key_name

  user_data_replace_on_change = true


  tags = {
    Name = "${var.env_prefix}-server"
  }
}

output "myapp_ip" {
    value = aws_instance.myapp_server.public_ip
}
```

8. Configured Terraform to install Docker and run nginx image

```
user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y && sudo yum install -y docker
                sudo systemctl start docker
                sudo usermod -aG docker ec2-user
                sudo docker run -p 8080:80 nginx
                EOF
```

Best practices:
- Create own VPC and leave the defaults created by AWS as is
- Security:  Store your .pem file ssh private key in .ssh folder. Restrict permission (only read for our User) on .pem file
- Security: Don’t hardcode public_key in Terraform config file!
- Terraform should be used only for initial infrastructure setup, manage infrastructure, initial application setup, and NOT to manage applications!

---

## Project 2

**Deploy EKS cluster**

1. Created the VPC by using the VPC module

2. Created the EKS cluster and worker nodes by using the EKS module

3. Configured Kubernetes provider to authenticate with K8s cluster

4. Deployed nginx Application/Pod

--- 

## Project 3
