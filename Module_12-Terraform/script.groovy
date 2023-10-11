def buildJar() {
    sh "cd Module_8-CICD_with_Jenkins/java-maven-app-master/ && mvn clean package"
} 

def buildImage(String IMAGE_NAME) {
    dir("Module_8-CICD_with_Jenkins/java-maven-app-master/") {
         withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
        //note: usernamePassword() requires the credentials to be of the kind "username with password".
        sh "docker build -t negru1andrei/java-maven-app:${IMAGE_NAME} ."
        sh "echo $PASS | docker login -u $USER --password-stdin"
        sh "docker push negru1andrei/java-maven-app:${IMAGE_NAME}"
        }
    }
} 

def deployApp(String IMAGE_NAME) {
    def dockerCmd = "docker run -d -p 8080:8080 negru1andrei/java-maven-app:${IMAGE_NAME}"
    sshagent(credentials: ['ec2-key']) {
        sh "ssh -o StrictHostKeyChecking=no ec2-user@18.194.140.242 ${dockerCmd}"
    }
}

def deployAppWithDockerCompose(String IMAGE_NAME, String PUBLIC_IP) {
    dir("./Module_12-Terraform") {
        withCredentials([usernamePassword(credentialsId: "dockerhub-credentials", passwordVariable: 'PASS', usernameVariable: "USER")]) {
        def shellCmd = "bash my-script.sh ${IMAGE_NAME} ${PASS} ${USER}"
        def ec2server = "ec2-user@${PUBLIC_IP}"

        echo "${ec2server}"

        sshagent(credentials: ['jenkins-aws-key']) {
            sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${ec2server}:/home/ec2-user"
            sh "scp -o StrictHostKeyChecking=no my-script.sh ${ec2server}:/home/ec2-user"
            sh "ssh -o StrictHostKeyChecking=no ${ec2server} ${shellCmd}"
        }
    }
    }
}

return this