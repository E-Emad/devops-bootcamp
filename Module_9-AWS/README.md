# AWS Module

AWS resources can be Global, Region based or AZs specific.\
Each AWS account should have an admin IAM user to administer the account. You can create IAM users and distribute those users in different groups. IAM Roles are attached to other AWS services that need to talk to each other (e.g EC2 will update items in a DynamoDB table).\

Resources should be created in Regions that are closer to end-users for low latency purpose. Each Region has 3 or more AZs.\
VPC spans an entire Region and helps to isolate the resources in your accounts from other accounts.\

Each VPC has many Subnets which spans over AZs. Subnets can be public or private. You secure subnets using NACLs (Network Access Control Lists). They act as a firewall at the network level. For securing traffic at the instance level, Security groups are used. CIDR blocks shows how many IPs are in it. E.g 10.0.0.0/32 - one single IP and 10.0.0.0/24 - first 24 bits are fixed, only last 8 can be changed => we will have IPs starting from 10.0.0.0 to 10.0.0.255. 

## Project 1

**Deploy Web Application on EC2 Instance (manually)**

1. Create an EC2 instance of type t2.micro (free tier) of name `my-ec2instance`

2. Choose an AMI within the free tier

3. Key pair is used to ssh into the instance. Creating a new key pair in AWS you have to specifiy the name and what format do you want for private key, which will be stored on your computer. .ppk for PuTTy (Windows) or .pem for OpenSSH (Linux, Mac). 

4. For Network settings - you can create a Security group allowing incoming traffic on SSH port 22 from your IP address only. Or if it's an app which listens on a specific port, add that Custom TCP rule (0.0.0.0/0 - allow incoming traffic from the internet)

5. To connect to instance use shh and the public IP address. 

`ssh -i "aws-key-m2.pem" ec2-user@18.194.140.242` - ssh-ing usin ec2-user

6. Update the package manager repo of the instance

`sudo yum update`

7. Install Docker

`sudo yum install docker`

8. Add ec2-user to the docker group to avoid using `sudo` with every docker command. 

`sudo usermod -aG docker ec2-user`

9. Log out from the instance and log in again with ec2-user

10. Start the Docker service using: `sudo service docker start`

11. Build a docker image from the Dockerfile in `react-nodejs-example-master` on your machine and push to your private docker hub repo. 

- update package.json to use `"react-scripts": "5.0.1"` and use `amd64/node:lts` in the Dockerfile on my-app 
- change to `react-nodejs-example-master` directory and run `docker build -t negru1andrei/react-nodejs-app:1.0 .`
- push to Docker Hub: `docker push negru1andrei/react-nodejs-app:1.0`

12. Inside the AWS instance, login to your Docker Hub account and start a container using that image. 

- `docker login --username negru1andrei --password yourpassword` 
- `docker run -d -p 3000:3080 --name react-node-container negru1andrei/react-nodejs-app:1.0` 

13. Make sure to open port 3000 for incoming traffic on Security group of the EC2 instance.

---

## Project 2 

**Deploy Application from Jenkins Pipeline to EC2 Instance (automatically with docker)**

1. I'll use the java maven app defined in `Module_8-CICD_with_Jenkins/java-maven-app-master`

2. Install the SSH Agent plugin on the Jenkins server

3. Store the key .pem used to ssh on the EC2 in the Jenkins credentials

4. Create a new pipeline in Jenkins that will use the Jenkinsfile and script.groovy from `Module_9-AWS`

5. Make sure to edit the Security group of the ec2 instance to allow incoming traffic on port 8080 coming from the IP of the Jenkins server.



