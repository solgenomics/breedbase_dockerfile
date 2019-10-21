#!/bin/bash

GIT_BRANCH="$(git --git-dir=repos/sgn/.git --work-tree=repos/sgn symbolic-ref -q --short HEAD)"
GIT_TAG="$(git --git-dir=repos/sgn/.git --work-tree=repos/sgn describe)"

# Build :devel image if sgn repo is on a branch, :production if it's on a tag

if [ $GIT_BRANCH ]
then
  printf "sgn repo is on branch $GIT_BRANCH, not checked out on a release tag. Building an image with tag :devel\n\n"
  docker build \
  --build-arg CREATED=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg REVISION=$(git --git-dir=repos/sgn/.git --work-tree=repos/sgn log -1 --format=%h) \
  --build-arg BUILD_VERSION=$GIT_BRANCH \
  -t breedbase/breedbase:devel .
  printf "Successfully built image breedbase/breedbase:devel\n\n"
  printf "For build details including version information use:\n\tsudo docker inspect breedbase/breedbase:devel | jq -r '.[0].Config.Labels'\n\n"
else
  printf "sgn repo is checked out on tag $GIT_TAG. Building an image with tag :production\n\n"
  docker build \
  --build-arg CREATED=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg REVISION=$(git --git-dir=repos/sgn/.git --work-tree=repos/sgn log -1 --format=%h) \
  --build-arg BUILD_VERSION=$GIT_TAG \
  -t breedbase/breedbase:production .
  printf "Successfully built image breedbase/breedbase:production\n\n"
  printf "For build details including version information use:\n\tsudo docker inspect breedbase/breedbase:production | jq -r '.[0].Config.Labels'\n\n"
fi
