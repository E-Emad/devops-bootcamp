# Jenkins module

## Project 1

**Install Jenkins on an EC2 as a Docker container**

I used a t2.large which has 2vCPU and 8 GiB Memory.
Security group inbound rules - allow for SSH on port 22 and HTTP on 8080. Default outbound rules are to allow everything.


1. Connect to the instance using ssh agent
`ssh -i "~/Downloads/key.pem" ubuntu@publiciphere`

2. Install Docker
`sudo apt update`\
`sudo apt install docker.io`\

`sudo groupadd docker` create a group called docker in case it's not created atomatically in installing docker\
`sudo usermod -aG docker ${USER}` add your user (ubuntu in this case) to that group in order to execute docker commands without sudo\

    and exit and reconnect to the EC2 through ssh

3. Start the Jenkins container

```
docker run -p 8080:8080 -p 50000:50000 -d \
-v jenkins_home:/var/jenkins_home jenkins/jenkins:lts-jdk11
```

port 8080 - accessing the Jenkins UI through browser\
port 50000 - where the communication between Jenkins master and worker nodes happens\

4. Initialize Jenkins

You can now connect to Jenkins UI using the public ip of the instance and the port 8080.

`docker container exec -it 213528dbf6e2 bash` - used to open the terminal inside container\
`cat /var/jenkins_home/secrets/initialAdminPassword` - to retreive the admin password that you need in the Jenkins UI\

--- 

## Project 2

**CI Pipeline (Freestyle job) to build and push to a private repo a java maven app**

1. Install Maven either in the Jenkins UI or directly in the container

Note: 
- job’s infor is stored in `/var/jenkins_home/jobs/my-job/builds`
- cloned repo is stored in `/var/jenkins_home/workspace/my-job`

2. Specify Git repo and execute shell scripts:
`cd ./Module_8-CICD_with_Jenkins/java-maven-app-master && mvn test` - run tests\
`cd ./Module_8-CICD_with_Jenkins/java-maven-app-master && mvn package ` - build artifact\ 

The jar file is stored under `/var/jenkins_home/workspace/my-freestyle-job/Module_8-CICD_with_Jenkins/java-maven-app-master/target` with the name\
`java-maven-app-1.1.0-SNAPSHOT.jar` because that's the name specified in pom.xml\

3. Make Docker available in Jenkins 

This is done by mounting docker runtime from host to the jenkins container.\
`docker run -d -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker jenkins/jenkins:lts`  --> does not work as expected, I had to install docker manually inside container.\

Use this command instead: `docker run -p 8080:8080 -p 50000:50000 -d -v /var/run/docker.sock:/var/run/docker.sock -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts`\
Enter inside container as root and run `curl https://get.docker.com/ > dockerinstall && chmod 777 dockerinstall && ./dockerinstall`\
then exit the jenkins container and change docker.sock privilege to read and write for all users with :
`sudo chmod 666 /var/run/docker.sock`. Now you have docker inside Jenkins.

4. Build the docker image and publish it to DockerHub

First create a repo for your Image on Docker Hub, then you have to add credentials to Jenkins in order to access your DockerHub.\
Go to Dashboard -> Manage Jenkins -> Manage Credentials -> Jenkins -> Global credentials -> Add Credentials (left sidebar)\
Create credentials to access your Docker Hub account.

Create the Dockerfile in `java-maven-app-master` directory.

Bind the DockerHub credentials created in Jenkins as a secure text and set `USERNAME` and `PASSWORD` as environment variables.

After the `mvn test && mvn package` add the following: 
```
cd ./Module_8-CICD_with_Jenkins/java-maven-app-master
docker build -t negru1andrei/java-maven-app:1.0.0 .
echo $PASSWORD | docker login -u $USERNAME --password-stdin
docker push negru1andrei/java-maven-app:1.0.0
```

---

## Project 3 

**Complete CI/CD Pipeline with Jenkins and using Groovy scripts**

- Jenkinsfile can be scripted or declarative:

    Scripted:\
        first syntax\
        Groovy engine\
        advanced scripting capabilities, high flexibility\
        difficult to start\
    Declarative\
        more recent addition\
        easier to get started, but not that powerful\
        pre-defined structure\

- The list of available environment variables can be seen at http://${JENKINS_URL}/env-vars.html

```
pipeline {
    agent any
    environment {
        // variables declared here will be available to all stages
        NEW_VERSION = '1.3.0'
    }
    // ...
}
```

- Using credentials in Jenkins - you need 2 plugins: Credentials Plugin and Credentials Binding Plugin\
- credentials("credentialId") binds the credentals to your env variable 
- another option is getting via usernamePassword()

-   Credentials Scopes
        System - only available on Jenkins Server (NOT for Jenkins jobs)
        Global - Everywhere accross Jenkins
        Project - limited to project, only available/accessible in the multibranch pipeline view
    Credentials Types
        Username & Password
        Certificate
        Secret File
        etc.
        (new types based on plugins)
    ID - that’s how you reference your credentials in scripts


1. Create a pipeline in Jenkins UI and specify the git repo and the Jenkinsfile path `./Module_8-CICD_with_Jenkins/java-maven-app-master/Jenkinsfile`

2. Create the pipeline stages in the Jenkinsfile

You can have the logic in the stages or extract logic in a Groovy script if you need to reuse code.\

3. Create a jenkins shared library repo
- used to share pipeline logic between multiple projects.
- extension to the pipeline
- has own repository
- written in Groovy
- reference shared logic in Jenkinsfile

`/vars` - contains all the functions that we will call from Jenkinsfile
`/src` - helper, utility for functions

---

## Project 4

---

## Project 5

**Dynamically increment application version in Jenkins pipeline**

1. Add stage to increment version app from pom.xml at the beginning of the pipeline
 
`mvn build-helper:parse-version versions:set \
-DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
versions:commit` -> this reads the pom.xml, increment patch version by one and save the newly created pom.xml

- `mvn clean package` -> first it deletes the /target directory where the artifacts are stored and then build the app and save the artifact in a clean /target

2. Commit version bump (newly created pom.xml) created by Jenkins to Git

- First you need an SSH Agent plugin 
- Create Credentials in Jenkins UI and add the private key generated on the Jenkins Server
- Use the id of the credentials in the sshagent step in Jenkinsfile
- Enter the jenkins container as jenkinser user and execute the following: `git ls-remote -h git@github.com:ngrandrei/devops-bootcamp.git HEAD` -> The host key for github will now be added to the ~/.ssh/known_hosts file