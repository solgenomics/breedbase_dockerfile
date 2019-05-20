# breedbase_dockerfile
The Dockerfiles for breeDBase

## Install docker (on Debian/Ubuntu)

apt-get install docker-ce

## Clone the repo

git clone https://github.com/solgenomics/breedbase_dockerfile

## Build the image

docker build -t breedbase_image breedbase_dockerfile

## Create the docker config

You need to write an sgn_local.conf file specific to your service. Then:

cat sgn_local.conf | docker config create -

## Run the service using swarm

docker service create --name "breedbase_service" --mount src=/export/prod/archive,target=/home/production/archive,type=bind --mount src=/export/prod/public_breedbase,target=/home/production/public,type=bind --config source="breedbase_sgn_local.conf",target="/home/production/cxgn/sgn/sgn_local.conf"  breedbase_image

## Set up forwarding in host using nginx

Done!

