## demo app - developing with Docker

This demo app shows a simple user profile app set up using 
- index.html with pure js and css styles
- nodejs backend with express module
- mongodb for data storage

All components are docker-based

### With Docker

#### To start the application

Step 1: Create docker network

    docker network create mongo-network 

Step 2: start mongodb and provide admin and password env variables to container

    docker run -d -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME=admin -e MONGO_INITDB_ROOT_PASSWORD=password --name mongodb --net mongo-network mongo    

Step 3: start mongo-express using the same credentials provided earlier to mongodb also specify the exact name of the mongo container
    
    docker run -d -p 8081:8081 -e ME_CONFIG_MONGODB_ADMINUSERNAME=admin -e ME_CONFIG_MONGODB_ADMINPASSWORD=password --net mongo-network --name mongo-express -e ME_CONFIG_MONGODB_SERVER=mongodb mongo-express   

_NOTE: creating docker-network in optional. You can start both containers in a default network. In this case, just emit `--net` flag in `docker run` command_

Step 4: open mongo-express from browser

    http://localhost:8081

Step 5: create `user-account` _db_ and `users` _collection_ in mongo-express

Step 6: Start your nodejs application locally - go to `app` directory of project 

    cd app
    npm install 
    node server.js



Alternatively you create a docker image with: docker build -t my-app:1.0 but before that, you have to change the code in server.js
for mongoUrlDocker to be mongodb://admin:password@mongodbcontainername:27017 in order for the app to connect to mongodb. Also make sure you 
add include the app in the same network as mongodb. 

Note: You don't have to map any volume when starting the mongodb container because the latest version of mongo image already do that by default and the data is persisted.
    
Step 7: Access you nodejs application UI from browser

    http://localhost:3000

### With Docker Compose

#### To start the application

Step 1: start mongodb and mongo-express

    docker-compose -f docker-compose.yaml up
    
_You can access the mongo-express under localhost:8080 from your browser_
    
Step 2: in mongo-express UI - create a new database "my-db"

Step 3: in mongo-express UI - create a new collection "users" in the database "my-db"       
    
Step 4: start node server 

    cd app
    npm install
    node server.js
    
Step 5: access the nodejs application from browser 

    http://localhost:3000

#### To build a docker image from the application

    docker build -t my-app:1.0 .       
    
The dot "." at the end of the command denotes location of the Dockerfile.


Create Nexus repository as a Docker container

Step 1: Pull the image from the Docker Hub with: docker pull sonatype/nexus3 

Step 2: docker run -d -p 8081:8081 --name nexus sonatype/nexus3  -> make sure that the port you are trying to bind from the host is not in use for any service

Step 3: When stopping, make sure you allow suffiecient time for database to fully shut down.

	docker stop --time=120 <CONTAINER_NAME>


- You don't have to create a non-root user inside the container becasue the nexus image is already configured to create a nexus user. 
- To persist data you have to create a volume and attach it to the container
- To find the actual file where the volume is mounted on the host, you have to: docker inspect volume_name

## Project 1

**Node using mongodb and Mongo express - containers**

1. Create a docker network for Mongo and Mongo-express to communicate

`docker network create mongo-network`

2. Build the docker image for the app from the Dockerfile

`docker build -t my-app:1.0 .` - will create an image called `my-app:1.0` 

3. Create a mongodb container from the mongo image

```docker run -d \
-p 27017:27017 \
-e MONGO_INITDB_ROOT_USERNAME=admin \
-e MONGO_INITDB_ROOT_PASSWORD=password \
--name mongodb \
--network mongo-network \ 
mongo
```

4. Create the mongo-express container and connect to mongodb container

```docker run -d \
-p 8081:8081 \
-e ME_CONFIG_MONGODB_ADMINUSERNAME=admin \
-e ME_CONFIG_MONGODB_ADMINPASSWORD=password \
-e ME_CONFIG_MONGODB_SERVER=mongodb \
--name mongo-express \
--network mongo-network \ 
mongo-express
```

`docker container prune` - if you created the containers without specifying the network, you can remove all of the stopped containers with this command 

5. Start de nodejs application as a docker container in the same network as the mongo and mongo-express

```docker run -d \
-p 3000:3000 \
--name my-app \
--network mongo-network \
my-app:1.0
```

Note: Stopping and starting a Docker container using the docker stop and docker start commands is a safe way to temporarily halt the container without deleting its data. If you want to ensure data persistence across container restarts and even container removals, it's a good practice to use Docker volumes or other data persistence mechanisms.

---

## Project 2

**Run containers with docker-compose**

1. Make sure to use `mongoUrlDockerCompose` url in the `server.js`. 

2. If you changed the code in `server.js`, make sure you build the image again. 

`docker build -t my-app:2.0 .`

3. Run `docker-compose up -d` to start all 3 containers


---

## Project 3

**Dockerize nodejs app and push to private Docker registry (ECR)**

Note: If you have multiple AWS accounts configured in config and credentials, you can switch between them by setting the environment variable `export AWS_DEFAULT_PROFILE=nameoftheprofile`. Now `--profile nameoftheprofile` can be omitted. 


1. Create `nodejs-app` repository in AWS ECR.
    - will contain every tags of that image. 
    - for another image, a new repository must be created.

2. Login to AWS ECR

`aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 447090147243.dkr.ecr.eu-central-1.amazonaws.com`

3. Build the `nodejs-app` image from the Dockerfile

`docker build -t nodejs-app .`

4. Rename the image to contain the repository name from ECR

`docker tag nodejs-app:latest 447090147243.dkr.ecr.eu-central-1.amazonaws.com/nodejs-app:1.0`

5. Push the image to ECR

`docker push 447090147243.dkr.ecr.eu-central-1.amazonaws.com/nodejs-app:1.0`

---

## Project 4

**Deploy Nodejs app with Mongo and Mongo-express on a server using docker-compose**

1. Change the code in `server.js` in order to use `mongoUrlDockerCompose` variable because when building multiple containers with \
docker-compose they can connect to each other using only the container name, no need for localhost and port. 

2. Build the `nodejs-app` image from the Dockerfile

`docker build -t nodejs-app:1.1 .`

3. Rename the image to contain the repository name from ECR

`docker tag nodejs-app:1.1 447090147243.dkr.ecr.eu-central-1.amazonaws.com/nodejs-app:1.1`

4. Push the image to ECR

`docker push 447090147243.dkr.ecr.eu-central-1.amazonaws.com/nodejs-app:1.1`

5. Create the docker-compose file

6. Run all 3 containers using `docker-compose up -d`

---


# Docker resources

● Best practices for writing Dockerfiles: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
● Docker development best practices: https://docs.docker.com/develop/dev-best-practices/
● Tips for Caching, reducing Image size, maintainability, reproducibility: https://www.docker.com/blog/intro-guide-to-dockerfile-best-practices/
● Tip: Enforce Dockerfile best practices automatically by using a static code analysis tool (e.g. https://github.com/hadolint/hadolint )