#!/bin/bash

# Make sure to start boot2docker before running this script
eval "$(docker-machine env default)"

/usr/local/bin/docker login

read -p "What version number or tag are you deploying? " tag

if [[ $tag ]]; then
  /usr/local/bin/docker build -t globalfoodbook/gfb:$tag .
  /usr/local/bin/docker push globalfoodbook/gfb:$tag

  /usr/local/bin/docker build -t globalfoodbook/gfb:latest .
  /usr/local/bin/docker push globalfoodbook/gfb:latest
else
  echo -e "Kindly provide a tag or version number"
fi
