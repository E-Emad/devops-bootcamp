export IMAGE_TAG=$1
export DOCKER_PASS=$2
export DOCKER_USR=$3

echo $DOCKER_PASS | docker login -u $DOCKER_USR --password-stdin
docker-compose up -d 
echo "java app and postgres should be up and running"