#!/bin/bash

# Remove all the running containers

echo "**************** Removing containers ******************"
docker rm -f $(docker ps -aq)
