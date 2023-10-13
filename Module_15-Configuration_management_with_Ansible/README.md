# Ansible

Ansible is used to configure systems and deploy software on the existing infrastructure.\
It can be used for repetitive tasks such as update, backups, create users & assign permissions, system reboots or apply a configuration on multiple servers all at once.\

**How it works?**

It uses yaml files. Anisble is agentless, meaning that you don't have to install Ansible agent on every server. Ansible connects to remote servers using simple SSH.\
Modules are reusable, standalone scripts that Ansible runs on your behalf. They are granular and perform a specfic task. You can develop your own modules or use existing ones.\

A Playbook groups mutiple modules together and executes them in order from top to bottom.\

Instal Ansible either by running `brew install ansible` on macos or `pip install ansible` for any other os. 

**HOSTS** defines where the tasks get executed\
**REMOTE_USER** defines with which user the tasks should be executed\

Playbook consists of 1 or more plays. Each play executes part of the overall goal of the playbook. A play executes one or more tasks. Each tasks calls one Ansible module.\

Ansible Tower - web-based solution that makes Ansible more easy to use.\

Alternatives to Ansible - Chef and Puppet (you need to install agent on the target machines & based on Ruby programming language)\

Ansible can be installed on your local machine or on a remote server (in this cased is called Control Node). Windows is not supported as a Control Node. It also needs Python to be installed. 

**Ansible Inventory**

- file containing data about target remote hosts and how to connect to them (hosts IP or DNS names, SSH private keys, SSH user). 
- to address multiple hosts you can group them based on their functionality, region, environment, etc. 
- example of adhoc command: `ansible all -i hosts -m ping` where -i = inventory and -m = module name

**Host Key Checking**

- is enabled by default in Ansible
- it protects against server spoofing and man-in-the-middle attacks

If you have long-living servers, you can handle the Host key checking by adding the target servers to the known hosts of the Ansible server. You can do that with `ssh-keyscan -H IPOFSERVER >> ~/.ssh/known_hosts`. Next, if you have make sure that the target server contains the public ssh key (can be found in `.ssh/authorized_keys`).\

If you have ephemeral servers, you can disable entirely the host key check:
- Config file default locations: `/etc/ansible/ansible.cfg` or `~/.ansible.cfg` -> add here the `host_key_checking = False`

**Ansible Playbooks**

- a Playbook can have multiple Plays
- a Play is a group of tasks

- `Gather Facts` module is automatically called by Playbooks to gather useful variables about remote hosts that you can use in Playbooks
- Ansible executes a module on the remote server

Ansible v2.9 and earlier is a single package with ansible code and modules where Ansible v2.10 and later modules and plugins moved separately into various collections. 

**Ansible Collections**

Collection - single bundle containing modules, playbooks, plugins.\
Colletions can be released & installed independent from other colletions.\

- Built-in Collections - ansible.builtin for example
- Ansible Galaxy - online hub for finding and sharingAnsible community content, like PyPi, Terraform Registry, etc.\
                 - also a CLI utility to install colletions

**Ansible Variables**

- used to parameterize your Playbook to make it customizable, so we can use the same Ansbile script for different environments, by substituting some dynamic values.
- With "register" you can create variables from the output of an Ansible task; This variable can be used in any later task in your Play
- reference variable using double curly braces

You can set variables directly in the Playbook, on the command line or using external variable configuration file like Terraform.

Extra materials:
 - https://aap2.demoredhat.com/decks/ansible_best_practices.pdf
 - https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html
 - https://www.ansible.com/blog/ansible-best-practices-essentials

## Project 1

**Automate Node.js application deployment on a Ubuntu server**

1. Create EC2 server on AWS

2. Write Ansible playbook that installs node and npm, creates linux user for the app and deploy the NodeJS app with that user.

- npm used to install app dependencies and node to start the app

- EC2 created with a Ubuntu AMI -> apt as a package manager

- `npm pack` - to create the tgz file with the app -> when unpacking the tgz you will get `package` folder with app/ and package.json

- `async` and `poll` are used to run the task asyncronously -> the playbook run might finish but the node start can be in progress on the server

Ansible file: `deploy-node-app.yaml`

---

## Project 2 

**Ansible, Docker and Docker-compose on a Amazon Linux 2 server**

- `command` and `shell` modules to be used as the last alternative because they don't have state management

1. Create an EC2 instance with Amazon Linux 2 AMI using Terraform or AWS Console. 

2. Install docker and docker-compose using yum module

- The lookup plugin is always executed on the control node (that's your Ansible server), which is to say that the lookup plugin does not do something on your managed nodes (the target systems). To get the OS name and architecture of the hosts, you can use `ansible_system` and `ansible_architecture` which are set by the gathering facts task automatically. 

3. Start docker daemon

- to start docker daemon you can use `systemd` module

4. Create docker user and add it docker group in order to use docker as a non-root user

- `users` will output just the connected users to the host
- `groups` will output just the groups that the connected user is part of
- `cat /etc/passwd` - outputs all users on the host
- `cat /etc/group` - outputs all groups and the users who are part of each group

5. Copy docker-compose.yaml file to remote

6. Login to Private docker registry

7. Execute docker-compose to start the containers

---

## Project 3

**Ansible integration with Terraform**

1. Create Ansible playbook which will be run by Terraform once a server is provisioned

- `ansible.builtin.wait_for` module will wait 2 minutes for the port 22 to be available and execute the rest of the playbook only once the server newly created is ready.

2. Create `main-ansible.tf` terraform file 

- `null_resource` does not create any tf resource
- `local_exec` because terraform will pick the ansible playbook from local machine, and ansible with connect via SSH to target hosts.

---

## Project 4

**Dynamic inventory**

1. Create 3 EC2 servers with Terraform

2. Connect to those servers with Ansible without hardcoding the IP Addresses.

- connect to AWS account and get servers information usign Inventory Plugins or Scripts. Plugins are recommended because it has state management. 
- `enable_plugins = amazon.aws.aws_ec2` in .cfg 
- file with `aws_ec2.yaml` suffix has to be created
- test the inventory plugin with `ansible-inventory -i inventory_aws_ec2.yaml --list` or `--graph`
- make sure the VPC is configured to assign public DNS names to servers, otherwise, the plugin will get private DNS names of the servers (those can be used only if the Ansible is in the same VPC with the targeted hosts)
- hosts in Ansible playbook will become `aws_ec2` to target all the hosts, or the tag used to differentiate between servers

--- 

## Project 5 

**Automate K8s deployment**

1. Create EKS cluster with Terraform

- switch to `terraform/project-3-deploy-eks-cluster` branch and run `terraform apply` in the `Module_12-Terraform` directory to provision EKS cluster on AWS
- run `aws eks update-kubeconfig --name myapp-eks-cluster --region eu-central-1` to update your local kube config file needed to authenticate with the cluster

2. Write Ansible Play to deploy application in a new K8s namespace

- `Kubernetes.Core` - the collection used
- `ansible-galaxy collection install kubernetes.core` - to install the collection
- you can write the whole k8s configuration in an Ansile play as both uses same syntax
- By default the Kubernetes Rest Client will look for ~/.kube/config, and if found, connect using the active context. You can override the location of the file using the kubeconfig parameter, and the context, using the context parameter

- make sure you have installed on your local machine
```


    python >= 3.6

    kubernetes >= 12.0.0

    PyYAML >= 3.11

    jsonpatch


```
- `hosts: localhost` - you don't need to specify any worker node or master because ansible with connect to the cluster using kubeconfig

3. Run `ansible-playbook deploy-to-k8s.yaml`

--- 

## Project 6

**Ansible Integration in Jenkins**

1. Make sure you have a Jenkins server up and running

- if not, follow the steps to create one as a Docker container found here: `Module_8-CICD_with_Jenkins/README.md`

2. Create an ubuntu server on AWS that will host Ansible

- `ssh -i .ssh/ansible-key-pair.pem ubuntu@3.78.221.162` and install Ansilbe and boto3 package:
```
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y 

sudo apt install python3-pip -y
pip3 install boto3
```

- we need AWS credentials available on the Ansible control node because of the dynamic inventory 

```
mkdir .aws
vim credentials  // paste here your aws access key id and secret access key
```

3. Create 2 EC2 instances that will be managed by Ansible Control Node

- create a new key pair `ansible-jenkins` - private key will be provided to Ansible in order to connect with those 2 instances

4. Create Jenkins credentials in UI with `ansible-key-pair` used to connect to the Anisble server name it `ansible-connection` (of type shh user with password)

5. Create Jenkins credentials in UI with `ansible-jenkins.pem` used by Ansible to connect to the managed EC2 instances. Name it `managed-ec2`. 

- this key will need to be copied from Jenkins server to Ansible server and used in the `ansible.cfg` to `private_key_file = ~/ssh-key.pem`. 

5. Create step in Jenkinsfile to copy `ansible.cfg`, `inventory_aws_ec2.yaml` and `deploy-docker-from-jenkins.yaml` from Jenkins server to Ansible server. 

- don't forget to copy also the `managed-ec2` from Jenkins to Ansible in order for Ansible to manage the EC2s. 
- if you want to use a sensitive variable and an environment variable in a same shell command, you could still use double quotes (" ") but make sure you escape the $ of the sensitive variable with `\` - in this case it will not be interpolated on the level of groovy and will be passed as is to the shell and environment variable will be used on the level of shell.

```
script {
    dir("Module_15-Configuration_management_with_Ansible") {
        sshagent(credentials: ['ansible-connection']) {
        sh "scp -o StrictHostKeyChecking=no ansible.cfg deploy-docker-from-jenkins.yaml inventory_aws_ec2.yaml ubuntu@${ANSIBLE_SERVER_ADDRESS}:/home/ubuntu"
        withCredentials([sshUserPrivateKey(credentialsId: "managed-ec2", keyFileVariable: "keyfile", usernameVariable: "user")]) {
                sh "scp \$keyfile ubuntu@${ANSIBLE_SERVER_ADDRESS}:/home/ubuntu/ssh-key-temp.pem"
                sh "ssh ubuntu@${ANSIBLE_SERVER_ADDRESS} 'mv ssh-key-temp.pem ssh-key.pem && rm -f ssh-key-temp.pem'"
            }
        }
    }
}
```

- because when copying the keyfile from Jenkins to Ubuntu server using the ubuntu user, the keyfile will have only R permissions for ubuntu and subsequent runs of the pipeline will fail to copy a new keyfile to that location. To overcome this, first copy the keyfile in a temporary location then ssh into the server to rename that keyfile to the one that Ansible will use and remove the temporary keyfile. 

6. Create the step that executes `ansible-playbook` on the Jenkinsfile using SSH Pipeline steps that facilitates command execution for continuous delivery.

When using the SSH Pipeline steps plugin with `sshUserPrivateKey` passed to `withCredentials` I got `com.jcraft.jsch.JSchException: Auth fail`.\
In order to debug this further, connect to the ubuntu server where Ansible is running and check the logs of the ssh deamon: `cat /var/log/auth.log`.

In the logs you can see the following from the connection comming from the Jenkins Server:

```
ip-172-31-11-170 sshd[9989]: userauth_pubkey: key type ssh-rsa not in PubkeyAcceptedAlgorithms [preauth]
ip-172-31-11-170 sshd[9989]: error: Received disconnect from 3.120.209.48 port 53972:3: com.jcraft.jsch.JSchException: Auth fail [preauth]
```

To fix it you have to add `PubkeyAcceptedAlgorithms +ssh-rsa` in the ssh configuration: `/etc/ssh/sshd_config`.
Restart the ssh deamon after that: `sudo systemctl restart sshd`.

