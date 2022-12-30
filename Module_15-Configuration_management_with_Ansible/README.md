# Ansible

Ansible is used to configure systems and deploy software on the existing infrastructure.\
It can be used for repetitive tasks such as update, backups, create users & assign permissions, system reboots or apply a configuration on multiple servers all at once.\

**How it works?**

It uses yaml files. Anisble is agentless, meaning that you don't have to install Ansible agent on every server. Ansible connects to remote servers using simple SSH.\
Modules are reusable, standalone scripts that Ansible runs on your behalf. They are granular and perform a specfic task. You can develop your own modules or use existing ones.\

A Playbook groups mutiple modules together and executes them in order from top to bottom.\

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

