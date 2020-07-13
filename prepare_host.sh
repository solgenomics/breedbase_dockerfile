#!/bin/bash

# Script to prepare a host for breedbase docker
# host needs a few dirs with correct permissions
# the dirs are mounted into the docker with the docker-compose.yml
# Run as:
# sudo bash prepare_host.pl /home/production
#
# Lukas, 2020-03-14

export DIR=""

if [ ! -z "$1" ]
then
    echo "USING $1...";
    export DIR="$1";
else
    echo "USING $HOME...";
    export DIR="$HOME";
fi

echo "Preparing directories... (Using $DIR)";

mkdir "$DIR/tmp"
chown www-data "$DIR/tmp"

mkdir "$DIR/archive"
chown www-data "$DIR/archive"

mkdir "$DIR/cache"
chown www-data "$DIR/cache"

mkdir "$DIR/images"
chown www-data "$DIR/images"

mkdir "$DIR/cluster"
chown www-data "$DIR/cluster"

mkdir "$DIR/pgdata"
chown postgres "$DIR/pgdata"

mkdir "$DIR/blast"

echo "Done."
