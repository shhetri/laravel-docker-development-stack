#!/bin/bash

source ./env.sh

echo "Stopping all the containers..."
STOP_COMPOSE=$(docker-compose kill)

echo "Stopping $PROJECT_CONTAINER_NAME container..."
STOP_PROJECT_CONTAINER=$(docker stop $PROJECT_CONTAINER_NAME)
