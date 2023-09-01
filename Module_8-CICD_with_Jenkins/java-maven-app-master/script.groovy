def buildJar() {
    sh "cd ./Module_8-CICD_with_Jenkins/java-maven-app-master/ && mvn clean package"
} 

def buildImage(String IMAGE_NAME) {
    dir("./Module_8-CICD_with_Jenkins/java-maven-app-master/") {
         withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
        //note: usernamePassword() requires the credentials to be of the kind "username with password".
        sh "docker build -t negru1andrei/java-maven-app:${IMAGE_NAME} ."
        sh "echo $PASS | docker login -u $USER --password-stdin"
        sh "docker push negru1andrei/java-maven-app:${IMAGE_NAME}"
        }
    }
} 

def deployApp() {
    echo 'deploying the application...'
} 

return this