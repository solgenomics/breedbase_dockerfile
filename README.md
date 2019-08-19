# breedbase_dockerfile
The Dockerfiles for breeDBase

## Install docker (on Debian/Ubuntu)
```bash
apt-get install docker-ce
```

## Installing through docker hub
To install through docker hub:
```
docker pull breedbase/breedbase
```
This will pull in the latest release of the system. This is the preferred way for production systems.

## Installing from the repo

Alternatively, the docker image can be built using the github breedbase_dockerfile repo, as explained below. This is recommended if you would like to develop based on the docker.

### Clone the repo
```bash
git clone https://github.com/solgenomics/breedbase_dockerfile
```

### Run the prepare.sh script from within the breedbase_dockerfile dir
```
cd breedbase_dockerfile
./prepare.sh
```
This will clone all the git repos that are needed for the build into a directory called ```repos/```. 
You can then checkout particular branches or tags in the repo before the build.

### Build the image
```bash
docker build -t breedbase_image breedbase_dockerfile
```
## Running the docker

There are a couple of ways in which the docker can be run: (1) using ```docker swarm```, or (2) using ```docker run```. 
In both cases, the docker can be run using the postres_docker docker to provide the database.

### Running using ```docker swarm```

Once the docker image has been created either through docker hub or by building the image, the docker can be started. First, The docker swarm needs to be initialized on the machine. This needs to be done only once.

```bash
docker swarm init
```

#### Create the docker config
You need to write an ```sgn_local.conf``` file specific to your service. A template is provided in the breedbase_dockerfile repo (you have to fill in the db server host, dbname, and username and password). Then:
```bash
cat sgn_local.conf | docker config create "breedbase_sgn_local.conf" -
```

#### Run the service using swarm

To run the docker on the swarm, you have to provide the config using ```--config```, as well as any mounts that are required for presistent data. Currently, breedbase just mounts directories on the docker host (which can be nfs mounts), but later this could be changed to docker volumes. Multiple mountpoints can be provided with multiple ```--mount``` options, as follows:
```bash
docker service create --name "breedbase_service" --mount src=/export/prod/archive,target=/home/production/archive,type=bind --mount src=/export/prod/public_breedbase,target=/home/production/public,type=bind --config source="breedbase_sgn_local.conf",target="/home/production/cxgn/sgn/sgn_local.conf"  breedbase_image
```

Depending on where your database is running, you may need to use the --network option. For a database server running on the host machine (localhost in your sgn_local.conf), use --network="host".

### Running using ```docker run```

Using ```docker run```, you also need to prepare an ```sgn_local.conf``` file as above.

Base docker run command:
```
docker run -d -p 7080:8080 -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive breedbase/breedbase:latest
```

### Running using the ```postgres_docker``` database backend

For more information on how to use the postgres_docker backend, see its README file.

Connecting Breedbase DB container:
```
docker run -d -p 7080:8080 --link breedbase_db_container_name:db -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive breedbase/breedbase:latest
```

## Developing using docker

The docker only contains static copies of the git repos. To develop using docker, you can mount the /home/production/cxgn/breedbase_dockerfile/repos (or your equivalent) in the docker file system at /home/production/cxgn, using the following option: 
``` --mount src=/home/production/cxgn/breedbase_dockerfile/repos,target=/home/production/cxgn```

This allows docker to see your actual git checkouts which you can modify, and all the authentication info for github etc. is safely in your host computer.

For development, you can also use the ``` -e MODE=DEVELOPMENT``` flag, which will run the site using Catalyst instead of Starman. In this configuration, the server will restart when any changes are detected in the code libraries. It is recommended to mount the git directories from the host (the docker images only contains static copies): 

```
docker run -d -p 7080:8080 -e MODE=DEVELOPMENT -v /host/path/to/sgn:/home/production/cxgn/sgn -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive breedbase/breedbase:latest
```

## Debugging
The service should be visible on that host now. To debug, log into the container. You can find the container id using
```
docker ps
```
then
```
docker exec -it <container_id> bash
```
You can use ```lynx localhost:8080``` to see if the server is running correclty within the docker, and look at the error log usign ```tail -f /var/log/sgn/error.log``` or ```less /var/log/sgn/error.log```.

You can of course also find the IP address of the running container either in the container using ```ip address``` or from the host using ```docker inspect <container_id>```.

### Set up forwarding in host using nginx
Finally, set up nginx or apache2 forwarding to the container. It is recommended to use a secure http connection (https).

### Docker Hub
You should be able to download the latest images from docker hub, at hub.docker.com, breedbase/breedbase:latest, using
```
docker pull breedbase/breedbase:latest
```
