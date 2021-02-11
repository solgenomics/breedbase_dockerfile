#!/bin/bash

docker build \
--build-arg CREATED=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
-t breedbase/breedbase:latest .
printf "Successfully built image breedbase/breedbase:latest\n\n"
printf "For build details run:\n\tsudo docker inspect breedbase/breedbase:latest | jq -r '.[0].Config.Labels'\n\n"
