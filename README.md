# breedbase_dockerfile
The Dockerfile for [breeDBase](https://github.com/solgenomics/sgn)

# Starting a Breedbase instance
There are a few ways in which the image can be run: (1) [using docker swarm](#using-docker-swarm), (2) [using docker run](#using-docker-run), or (3) [using docker compose](#using-docker-compose).  Before running the image, some prereqs must be satisfied.

## Prereqs

### Docker
For installing on Debian/Ubuntu:

```bash
apt-get install docker-ce
```

For Mac/Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)

### Database

A Postgres database will need to be running and configured.  

To get up and running quickly, the `breedbase/pg` image can be used:
```bash
docker run -d --name breedbase_db -p 5432:5432 breedbase/pg:latest
```

This will create a base empty Breedbase database.

For more information, visit: https://github.com/solgenomics/postgres_dockerfile

### Breedbase Configuration

You need to write an `sgn_local.conf` file specific to your service. A [template](./sgn_local.conf.template) is provided in the breedbase_dockerfile repo (you have to fill in the `dbhost`, `dbport`, `dbname`, and `dbuser` and `dbpassword`).

## Using `docker swarm`
Docker Swarm allows you to define a service, as well as to allow you to configure auto scaling and clustering of a service.

1. (If needed) Initialize Docker Swarm

    Once the image has been created either through Docker Hub or by building the image, the image can be started. First, Docker Swarm needs to be initialized on the machine. This needs to be done only once.
    
    ```bash
    docker swarm init
    ```
1. Add `sgn_local.conf` to docker config
    ```bash
    cat sgn_local.conf | docker config create "breedbase_sgn_local.conf" -
    ```
1. Start the service
    
    To run the image on swarm, you have to provide the `sgn_local.config` using `--config`, as well as any mounts that are required for persistent data. Currently, breedbase just mounts directories on the docker host (which can be nfs mounts), but later this could be changed to docker volumes. Multiple mountpoints can be provided with multiple `--mount` options, as follows:
    ```bash
    docker service create --name "breedbase_service" --mount src=/export/prod/archive,target=/home/production/archive,type=bind --mount src=/export/prod/public_breedbase,target=/home/production/public,type=bind --config source="breedbase_sgn_local.conf",target="/home/production/cxgn/sgn/sgn_local.conf"  breedbase_image
    ```

    Depending on where your database is running, you may need to use the `--network` option. For a database server running on the host machine (localhost in your sgn_local.conf), use `--network="host"`.
1. Access the application

    Once the service is running, you can access the application at http://localhost:7080

## Using `docker run`
Docker run allows you to define and start a single instance of a container.
 
1. Start the container

    Using `docker run`, `sgn_local.conf` will be directly mounted into the image instead of reading from Docker's config store
    
    Base docker run command:
    ```
    docker run -d --name breedbase_web -p 7080:8080 -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive -v /host/path/to/public_breedbase:/home/production/public breedbase/breedbase:latest
    ```
1. Access the application

    Once the container is running, you can access the application at http://localhost:7080
    
## Using `docker-compose`
Docker compose allows you to configure one or more containers and their dependencies, and then use one command to start, stop, or remove all of the containers. 

1. Install docker-compose

    Debian/Ubuntu: https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-18-04
    
    For Mac/Windows: It will have been installed as part of installing [Docker Desktop](https://www.docker.com/products/docker-desktop)
1. Download the Breedbase `docker-compose.yml` file

    [docker-compose.yml](./docker-compose.yml)

1. Change directories to where the `docker-compose.yml` file is located

1. Place `sgn_local.conf` in same directory as `docker-compose.yml`

1. Update `sgn_local.conf`

    Assuming you haven't modified the `docker-compose.yml` file, set the following:  
    
    ```
    dbhost breedbase_db
    dbport 5432
    ```
 
1. Starting the service
    
    ```bash
    docker-compose up -d breedbase
    ```
   
1. Access the application

    Once the container is running, you can access the application at http://localhost:7080

Helpful commands:

- Stopping the service

    This will stop all containers (both web and db), but will not remove the containers.
    ```bash
    docker-compose stop breedbase
    ```
   
- Starting a stopped service

    This will start all containers (both web and db) that were previously created, but have been stopped
    ```bash
    docker-compose start breedbase
    ```

- Stopping and removing the service
    
    This will stop all containers (both web and db), AND will remove them.
    
    *Note: You must be located in the directory where the `docker-compose.yml` file is located
    ```bash
    docker-compose down
    ```

## Debugging a running container
To debug, log into the container. You can find the container id using
```
docker ps
```
then
```
docker exec -it <container_id> bash
```
You can use `lynx localhost:8080` to see if the server is running correctly within the container, and look at the error log using `tail -f /var/log/sgn/error.log` or `less /var/log/sgn/error.log`.

You can of course also find the IP address of the running container either in the container using `ip address` or from the host using `docker inspect <container_id>`.

## (Optional) Connecting to a `breedbase/pg` container

If a `breedbase/pg` image is running on the same host that you are running the Breedbase container on (and you're not using `docker-compose`), then you can create a user-defined network within Docker.
A full description can be found in the Docker documentation here: [Docker user defined networks](https://docs.docker.com/network/)

1. Update `sgn_local.conf`

    Assuming you've named the Breedbase database container `breedbase_db`, in your `sgn_local.conf`, set the following:  
                                                                               
    ```
    dbhost breedbase_db
    dbport 5432
    ```
    
1. Create a network

    ```
    docker network create -d bridge bb_bridge_network
    ```
1. Add containers   

    Assuming you've named the Breedbase container `breedbase_web` and the Breedbase database container `breedbase_db`, run:

    ```
    docker network connect bb_bridge_network breedbase_db
    docker network connect bb_bridge_network breedbase_web
    ```

## Set up forwarding in host using nginx
Finally, set up nginx or apache2 forwarding to the container. It is recommended to use a secure http connection (https).

## Breedbase Admin User
If using `breedbase/pg` for a database, or you used `docker-compose`, the default admin username and password is:

```
username: admin
password: password
```

Once logged in, change the password of the admin user!!

# Manually building the image

Alternatively, the docker image can be built using the Github `breedbase_dockerfile` repo, as explained below. This is recommended if you would like to develop based on the image.

### Clone the repo
```bash
git clone https://github.com/solgenomics/breedbase_dockerfile
```

### Run the prepare.sh script from within the breedbase_dockerfile dir
```
cd breedbase_dockerfile
./prepare.sh
```
This will clone all the git repos that are needed for the build into a directory called `repos/`. 
You can then checkout particular branches or tags in the repo before the build.

### Build the image
```bash
docker build -t breedbase_image breedbase_dockerfile
```

# Developing using this image

Docker can be installed directly on to a development computer using Docker Desktop (https://www.docker.com/products/docker-desktop)

The Breedbase image only contains static copies of the git repos. To develop using docker, you can mount the /home/production/cxgn/breedbase_dockerfile/repos (or your equivalent) in the docker file system at /home/production/cxgn, using the following option: 

``` 
--mount src=/home/production/cxgn/breedbase_dockerfile/repos,target=/home/production/cxgn
```

This allows docker to see your actual git checkouts which you can modify, and all the authentication info for github etc. is safely in your host computer.

For development, you can also use the ` -e MODE=DEVELOPMENT` flag, which will run the site using Catalyst instead of Starman. In this configuration, the server will restart when any changes are detected in the code libraries. Again, it is recommended to mount the git directories from the host as well:

```
docker run -d -p 7080:8080 -e MODE=DEVELOPMENT -v /host/path/to/sgn:/home/production/cxgn/sgn -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive breedbase/breedbase:latest
```

# Running Breedbase behind a proxy server

In many situations, the Breedbase server will be installed behind a proxy server. While everything should run normally, there is an issue with ```npm```, and it needs to be specially configured. Create a file on the host server, let's say, ```npm_config.txt```, with the following lines in it:

```
strict-ssl=false
registry=http://registry.npmjs.org/
proxy=http://yourproxy.server.org:3128
https-proxy=http://yourproxy.server.org:3128
maxsockets=1
```
Of course, replace ```yourproxy.server.org:3128``` with your correct proxy server hostname and port. 

When running the docker, mount this file (using the ```volumes``` option in ```docker-compose``` or ```-v``` with ```docker run``` etc.) at the location ```/home/production/.npmrc``` in the docker. Then start your docker and now npm should be able to fetch dependencies from the registry.

# Running tests from the docker

To run tests from the docker, please note that the $HOME environment variable is set to ```/home/production```, so the ```.pgpass``` file will be written there. Most likely you will run the test as root, so the ```.pgpass``` file will be expected in the ```root``` directory. To make the tests work, first set ```$HOME``` to the correct dir: 
```
export HOME=/root
```
Also, the tests expect a ```web_usr``` role in the postgres instance. Log into the postgres instance and issue the commands:
```
create role web_usr with password '?????';
alter role web_usr with login;

```

Then, start the tests with (from the ```/home/production/cxgn/sgn``` dir):
```
t/test_fixture.pl t/unit_fixture/

```

# Updating the database from the docker

Code updates sometimes require the database structure to be updated. This is done based on so-called db patches. The db patches are in numbered directories in the the ```db/``` directory of the ```sgn``` repository. To update the database to the current level, run the ```run_all_patches.pl``` script in the ```db/``` directory. If you are using the standard docker-compose setup, the command line is:
```
    cd cxgn/sgn/db
    perl run_all_patches.pl -u postgres -p postgres -h breedbase_db -d
    breedbase -e admin [-s <startfrom>] [--test]
```
