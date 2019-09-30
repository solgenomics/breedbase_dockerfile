# breedbase_dockerfile
The Dockerfile for [breeDBase](https://github.com/solgenomics/sgn)

To pull this image:
```
docker pull breedbase/breedbase:latest
```

# Starting a Breedbase instance
There are a couple of ways in which the image can be run: (1) [using docker swarm](#using-docker-swarm), or (2) [using docker run](#using-docker-run).  Before running the image, some prereqs must be satisfied.

## Prereqs

### Docker
For installing on Debian/Ubuntu:

```bash
apt-get install docker-ce
```

For Mac/Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)

### Database

A Postgres database will need to be running and configured.  To get up and running quickly, follow the instructions for running the [postgres_dockerfile](https://github.com/solgenomics/postgres_dockerfile) image

### Breedbase Configuration

You need to write an `sgn_local.conf` file specific to your service. A [template](./sgn_local.conf.template) is provided in the breedbase_dockerfile repo (you have to fill in the `dbhost`, `dbport`, `dbname`, and `dbuser` and `dbpassword`).

## Using `docker swarm`

Once the image has been created either through Docker Hub or by building the image, the image can be started. First, Docker Swarm needs to be initialized on the machine. This needs to be done only once.

```bash
docker swarm init
```

1. Add `sgn_local.conf` to docker config
    ```bash
    cat sgn_local.conf | docker config create "breedbase_sgn_local.conf" -
    ```
1. Run the service using swarm
    To run the image on swarm, you have to provide the `sgn_local.config` using `--config`, as well as any mounts that are required for persistent data. Currently, breedbase just mounts directories on the docker host (which can be nfs mounts), but later this could be changed to docker volumes. Multiple mountpoints can be provided with multiple `--mount` options, as follows:
    ```bash
    docker service create --name "breedbase_service" --mount src=/export/prod/archive,target=/home/production/archive,type=bind --mount src=/export/prod/public_breedbase,target=/home/production/public,type=bind --config source="breedbase_sgn_local.conf",target="/home/production/cxgn/sgn/sgn_local.conf"  breedbase_image
    ```

    Depending on where your database is running, you may need to use the `--network` option. For a database server running on the host machine (localhost in your sgn_local.conf), use `--network="host"`.

## Using `docker run`

Using `docker run`, `sgn_local.conf` will be directly mounted into the image instead of reading from Docker's config store

Base docker run command:
```
docker run -d -p 7080:8080 -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive -v /host/path/to/public_breedbase:/home/production/public breedbase/breedbase:latest
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

## (Optional) Running using the `postgres_dockerfile` database backend
If a postgres_dockerfile image is running on the same host that you are running the Breedbase container on, then you can use the `--link` directive to facilitate inter-container network communication.

```
docker run -d -p 7080:8080 --link breedbase_db_container_name:db -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive breedbase/breedbase:latest
```

## Set up forwarding in host using nginx
Finally, set up nginx or apache2 forwarding to the container. It is recommended to use a secure http connection (https).

# Manually building the image

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
