
![BreeDBase](Breedbase.png)

This repo contains the Dockerfile for the breeDBase webserver, and the docker compose files for joint deployment of the breeDBase webserver and postgres database.
To learn more about breeDBase:

Access the [SGN repository](https://github.com/solgenomics/sgn) to contribute to the underlying codebase or submit new issues  
Access the [manual](https://solgenomics.github.io/sgn/) to learn how to use breeDBase's many features  
Access [breedbase.org](https://breedbase.org/) to explore a default instance of breeDBase.

#### Table of Contents  

[Deploy for Development](#deploy-for-development)  
[Deploy in Production](#deploy-in-production)  
[Deploy Individually](#deploy-individually)  
[Build a New Image](#build-a-new-image)  
[Debugging](#debugging)  


## Deploy for Development

1. Install docker-compose

    Debian/Ubuntu: https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-18-04

    For Mac/Windows: It will be installed as part of installing [Docker Desktop](https://www.docker.com/products/docker-desktop)

2. Clone this repo and set up other requirements on your host

    ```bash
    git clone https://github.com/solgenomics/breedbase_dockerfile
    ```
    Run the prepare.sh script from within the breedbase_dockerfile dir
    This will clone all the git repos that are needed for breedbase into a directory called `repos/`.
    This directory will be mounted onto the devel container during the compose step, but will still be accessible from the host for development work.
    ```
    cd breedbase_dockerfile
    ./prepare.sh
    ```
    Create a local conf file and archive dir on the host that will be mounted on the devel container
    ```
    mkdir archive
    cp sgn_local.conf.template  sgn_local.conf

    ```
3. Deploy with docker-compose and start developing!
    ```
    docker-compose up -d
    ```
    This will deploy 2 containers, `breedbase_web` and `breedbase_db`, combined in a single service named `breedbase`
    The deployment will set the container environment MODE to DEVELOPMENT, which will run the web server using Catalyst instead of Starman. In this configuration, the server will restart when any changes are detected in the config file or sgn perl libraries.

    Once the containers are running, you can access the application at http://localhost:7080

    When you first log in via the web, the default username and password are:
    ```
    username: admin
    password: password
    ```
    Once logged in, change the password of the admin user!!

    Docker has a [wealth of command-line options](https://docs.docker.com/engine/reference/commandline/docker/) for working with your new containers. Some commonly used commands include:  
    `docker ps -a` This will list all running containers and their details.  
    `docker-compose start breedbase` This will start both containers (web and db) that were previously created, but have been stopped.  
    `docker exec -it breedbase_web bash` This will open a new bash terminal session within the breedbase_web container.  
    `docker logs breedbase_web` This will allow you to access breedbase webserver error output from your host.  
    `docker-compose stop breedbase` This will stop both containers (web and db), but will not remove them.  
    `docker-compose down`   This will remove both containers, but only when run within the breedbase_dockerfile directory where the `docker-compose.yml` file is located.  


## Deploy in Production

### Using `docker compose`

1. Install docker-compose

    Debian/Ubuntu: https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-18-04

    For Mac/Windows: It will be installed as part of installing [Docker Desktop](https://www.docker.com/products/docker-desktop)

2. Clone this repo and set up an sgn_local.conf file

    ```
    git clone https://github.com/solgenomics/breedbase_dockerfile
    cd breedbase_dockerfile
    cp sgn_local.conf.template  sgn_local.conf
    ```
3. Deploy with docker-compose

    Make sure to specify both the base yml file and the production yml file with your command. These will overwrite the default development settings found in `docker-compose.override.yml`, and instead use production settings. These settings include pulling the latest image tagged `:production` from dockerhub, rather than `:devel`, setting env MODE to PRODUCTION rather than DEVELOPMENT, and mounting fewer volumes from the host (won't use host `/repos` dir to overwrite `/home/production/cxgn` in the container).  

    ```
    docker-compose -f docker-compose.yml -f production.yml up -d
    ```

### Using `docker swarm`
Docker Swarm allows you to define a service, as well as to allow you to configure auto scaling and clustering of a service.

You need to write an `sgn_local.conf` file specific to your service. A [template](./sgn_local.conf.template) is provided in the breedbase_dockerfile repo (you have to fill in the `dbhost`, `dbport`, `dbname`, and `dbuser` and `dbpassword`).

1. (If needed) Initialize Docker Swarm

    Once the image has been created either through Docker Hub or by building the image, the image can be started. First, Docker Swarm needs to be initialized on the machine. This needs to be done only once.

    ```bash
    docker swarm init
    ```

2. Add `sgn_local.conf` to docker config
    ```bash
    cat sgn_local.conf | docker config create "breedbase_sgn_local.conf" -
    ```

3. Start the service

    To run the image on swarm, you have to provide the `sgn_local.config` using `--config`, as well as any mounts that are required for persistent data. Currently, breedbase just mounts directories on the docker host (which can be nfs mounts), but later this could be changed to docker volumes. Multiple mountpoints can be provided with multiple `--mount` options, as follows:
    ```bash
    docker service create --name "breedbase_service" --mount src=/export/prod/archive,target=/home/production/archive,type=bind --mount src=/export/prod/public_breedbase,target=/home/production/public,type=bind --config source="breedbase_sgn_local.conf",target="/home/production/cxgn/sgn/sgn_local.conf"  breedbase_image
    ```

    Depending on where your database is running, you may need to use the `--network` option. For a database server running on the host machine (localhost in your sgn_local.conf), use `--network="host"`.

4. Access the application

    Once the service is running, you can access the application at http://localhost:7080


## Deploy Individually

1. Install docker

    Debian/Ubuntu: `sudo apt install docker.io`

    For Mac/Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)

2. Deploy Web Server

    This will create a Breedbase web server container. The -v flag is used to mount a local conf file and a couple of dirs from the host. Create the file and ris on your host if they don't exist and update the paths before running the command. If you will use this container for development it is also recommended to run `./prepare.sh` and mount the resulting `repos` repo at `/home/production/cxgn`.

    ```
    docker run -d --name breedbase_web -p 7080:8080 -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive -v /host/path/to/public_breedbase:/home/production/public breedbase/breedbase:latest
    ```

3. Deploy Postgres Database

    This will create an empty Breedbase postgres database container.

    ```
    docker run -d --name breedbase_db -p 5432:5432 breedbase/pg:latest
    ```

    For more information, visit: https://github.com/solgenomics/postgres_dockerfile

4. Connect containers via Docker Network

    Assuming you've named the Breedbase database container `breedbase_db`, in your `sgn_local.conf`, set the following:  

    ```
    dbhost breedbase_db
    dbport 5432
    ```

    Create a network and add your containers

    ```
    docker network create -d bridge bb_bridge_network
    docker network connect bb_bridge_network breedbase_db
    docker network connect bb_bridge_network breedbase_web
    ```

    Finally access the application at http://localhost:7080


## Build a New Image

If desired, a breedbase docker image can be built from scratch using this repo, as explained below. This is not recommended unless you have some time to kill, or are responsible for pushing a new image to dockerhub.

1. Clone the repo
    ```
    git clone https://github.com/solgenomics/breedbase_dockerfile
    ```

2. Run the prepare.sh script from within the breedbase_dockerfile dir
    ```
    cd breedbase_dockerfile
    ./prepare.sh
    ```
    This will clone all the git repos that are needed for the build into a directory called `repos/`.
    You can then checkout particular branches or tags in the repo before the build.

3. Build the image
    ```
    ./build.sh
    ```
    The build script will retrieve label metadata and run docker build. If the sgn repo is checked out on a branch, then your new build will be tagged `:devel`. If it is checked out on a git release tag your new image will be tagged `:production`.

4. Optional - Push to Dockerhub
    ```
    docker login
    ```
    then
    ```
    docker push breedbase/breedbase:devel
    ```
    or
    ```
    docker push breedbase/breedbase:production
    ```


## Debugging

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
