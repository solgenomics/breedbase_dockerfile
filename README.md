<p align="center">
  <img src="Breedbase.png">
</p>

This repo contains the Dockerfile for the breeDBase webserver, and the docker compose files for joint deployment of the breeDBase webserver and postgres database.
To learn more about breeDBase:

Access the [SGN repository](https://github.com/solgenomics/sgn) to contribute to the underlying codebase or submit new issues
Access the [manual](https://solgenomics.github.io/sgn/) to learn how to use breeDBase's many features
Access [breedbase.org](https://breedbase.org/) to explore a default instance of breeDBase.

#### Table of Contents

[Deploy in Production](#deploy-in-production)
[Deploy for Development](#deploy-for-development)
[Access and Configure](#access-and-configure)
[Debugging](#debugging)
[Testing](#testing)
[Miscellaneous](#miscellaneous)


## Deploy in Production

### Using `docker compose`

1. Install docker-compose

    Debian/Ubuntu: https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-18-04

    For Mac/Windows: It will be installed as part of installing [Docker Desktop](https://www.docker.com/products/docker-desktop)

    Please note that installing docker natively in Windows will conflict with VMWare and Virtualbox virtualization settings

2. Clone this repo and set up an sgn_local.conf file

    ```
    git clone https://github.com/solgenomics/breedbase_dockerfile
    cd breedbase_dockerfile
    cp sgn_local.conf.template  sgn_local.conf
    ```
3. Deploy with docker-compose

    Make sure to specify both the base yml file and the production yml file with your command. These will overwrite the default development settings found in `docker-compose.override.yml`, and instead use production settings. These settings include setting the env MODE to PRODUCTION rather than DEVELOPMENT, and mounting fewer volumes from the host (won't use host `/repos` dir to overwrite `/home/production/cxgn` in the container).

    ```
    docker-compose -f docker-compose.yml -f production.yml up -d
    ```
    Then follow [the instructions below](#access-and-configure) to access and configure your new breedbase deployment!

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


## Deploy for Development

1. Install docker-compose

    Debian/Ubuntu: https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-18-04

    For Mac/Windows: It will be installed as part of installing [Docker Desktop](https://www.docker.com/products/docker-desktop)

2. Clone this repo and set up other requirements on your host

    ```bash
    git clone https://github.com/solgenomics/breedbase_dockerfile
    ```
    Run the prepare.sh script from within the breedbase_dockerfile dir
    This will create a local conf file and clone all the git repos that are needed for breedbase into a directory called `repos/`.
    This directory will be mounted onto the devel container during the compose step, but will still be accessible from the host for development work.
    ```
    cd breedbase_dockerfile
    ./prepare.sh
    ```

3. Deploy with docker-compose, then follow [the instructions below](#access-and-configure) to access and configure your new breedbase deployment!
    ```
    docker-compose up -d
    ```

    This will deploy 2 containers, `breedbase_web` and `breedbase_db`, combined in a single service named `breedbase`
    The deployment will set the container environment MODE to DEVELOPMENT, which will run the web server using Catalyst instead of Starman. In this configuration, the server will restart when any changes are detected in the config file or sgn perl libraries.

    Docker has a [wealth of command-line options](https://docs.docker.com/engine/reference/commandline/docker/) for working with your new containers. Some commonly used commands include:
    `docker ps -a` Will list all running containers and their details.
    `docker-compose start breedbase` Will start both containers (web and db) if they have been stopped.
    `docker exec -it breedbase_web bash` Will open a new bash terminal within the web container.
    `docker logs breedbase_web` Will let you access webserver error output from your host.
    `docker-compose stop breedbase` Will stop both containers (web and db), but will not remove them.
    `docker-compose down`   Will remove both containers, but only if run within the breedbase_dockerfile directory.


## Access and Configure

Once your breedbase service is running, you can access the application at http://localhost:7080. User accounts can be created via the web interface, and their roles can be controlled by the default admin account:
```
username: admin
password: password
```
Please login and change the password of the admin user.

Most configuration is handled in the `sgn_local.conf` file. Just edit the corresponding configuration line in the file to change your database name, species, ontology, mason skin, etc.

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


## Testing

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


## Miscellaneous

### Running Breedbase behind a proxy server

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

### Updating the database schema from the docker

Code updates sometimes require the database schema to be updated. This is done using so-called db patches. The db patches are in numbered directories in the the ```db/``` directory of the ```sgn``` repository.

The db patches can be run individually by changing into the specific directory, and then running the script using ```mx-run```, using the parameters as described in the ```perldoc``` for the scripts.

The database can be updated to the current level in one step (recommended method) by running the ```run_all_patches.pl``` script in the ```db/``` directory, which calls all the db patches individually. If you are using the standard docker-compose setup, the command line is (options in square brackets are optional):
```
    cd cxgn/sgn/db
    perl run_all_patches.pl -u postgres -p postgres -h breedbase_db -d
    breedbase -e admin [-s <startfrom>] [--test]
```

Note that for this to work, the $PERL5LIB environment variable should have the current directory included. If it isn't, run:
```
    export PERL5LIB=$PERL5LIB:.
```

### Deploying Services Individually

 * Individual deployment is generally not necessary or recommended. When possible deploy jointly with docker compose *

1. Install docker

  Debian/Ubuntu: `sudo apt install docker.io`

  For Mac/Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)

2. Deploy a Web Server

  This will create a Breedbase web server container. The -v flag is used to mount a local conf file and a couple of dirs from the host. Create the file and ris on your host if they don't exist and update the paths before running the command. If you will use this container for development it is also recommended to run `./prepare.sh` and mount the resulting `repos` repo at `/home/production/cxgn`.

  ```
  docker run -d --name breedbase_web -p 7080:8080 -v /host/path/to/sgn_local.conf:/home/production/cxgn/sgn/sgn_local.conf -v /host/path/to/archive:/home/production/archive -v /host/path/to/public_breedbase:/home/production/public breedbase/breedbase:latest
  ```

3. Deploy a Postgres Database

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
