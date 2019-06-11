# breedbase_dockerfile
The Dockerfiles for breeDBase

### Install docker (on Debian/Ubuntu)
```bash
apt-get install docker-ce
```
### Clone the repo
```bash
git clone https://github.com/solgenomics/breedbase_dockerfile
```

### Run the prepare.sh script from within the breedbase_dockerfile dir
```
cd breedbase_dockerfile
./prepare.sh
```
This will clone all the git repos that are needed for the build into a directory called repos/. 
You can then checkout particular branches or tags in the repo before the build.

### Build the image
```bash
docker build -t breedbase_image breedbase_dockerfile
```
### Create the docker config

You need to write an ```sgn_local.conf``` file specific to your service. A template is provided in the breedbase_dockerfile repo (you have to fill in the db server host, dbname, and username and password). Then:
```bash
cat sgn_local.conf | docker config create -
```
### Run the service using swarm
To run the docker on the swarm, you have to provide the config using ```--config```, as well as any mounts that are required for presistent data. Currently, breedbase just mounts directories on the docker host (which can be nfs mounts), but later this could be changed to docker volumes. Multiple mountpoints can be provided with multiple ```--mount``` options, as follows:
```bash
docker service create --name "breedbase_service" --mount src=/export/prod/archive,target=/home/production/archive,type=bind --mount src=/export/prod/public_breedbase,target=/home/production/public,type=bind --config source="breedbase_sgn_local.conf",target="/home/production/cxgn/sgn/sgn_local.conf"  breedbase_image
```
### Debugging

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
