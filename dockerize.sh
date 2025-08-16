#!/bin/bash

if [[ $# = 0 || "$1" != "build" && "$1" != "run" && "$1" != "stop" ]]; then
    echo "Please supply a valid command:";
    echo "dockerize [build|run|stop]";
    exit;
fi

# Login to GitLab repo docker registry
docker login -u Docker-AT registry.gitlab.com/saxion.nl/hbo-ict/2.3-devops/2022-2023/87

#  Build - Create docker container for the backend application
if [[ "$1" = "build" ]]; then
    echo "Building...";
    # Remove old container
    docker rm chess_backend_c;
    # Remove old image
    docker rmi registry.gitlab.com/saxion.nl/hbo-ict/2.3-devops/2022-2023/87;
    docker compose build;
    echo "Done";

#  Run - Run the backend as a container in the background
elif [[ "$1" = "run" ]]; then
    echo "Starting...";
    docker compose up -d;
    echo "Done";

#  Stop - Stop the backend container
elif [[ "$1" = "stop" ]]; then
    echo "Stopping...";
    docker stop chess_backend_c;
    echo "Done";

fi