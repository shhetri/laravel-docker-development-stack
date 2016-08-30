#!/bin/bash

source ./env.sh

function stop_app(){
	sh ./docker-stop.sh
}

if hash docker 2>/dev/null; then
	PROJECT_CONTAINER=$(docker inspect --format="{{ .State.Running }}" $PROJECT_CONTAINER_NAME 2> /dev/null)

	if [ "$PROJECT_CONTAINER" == "true" ]; then
		echo "$PROJECT_CONTAINER_NAME container is already running..."
	elif [ "$PROJECT_CONTAINER" == "false" ]; then
		echo "Starting $PROJECT_CONTAINER_NAME container..."
		STARTING=$(docker start $PROJECT_CONTAINER_NAME 2> /dev/null)
	else
		echo "Creating $PROJECT_CONTAINER_NAME container..."
		CREATING=$(docker run \
			-p 5000:5000 \
			-v $PROJECT_CONTAINER_NAME:/var/www \
			-e UNISON_UID=82 \
			-e UNISON_USER=www-data \
			-e UNISON_DIR=/var/www \
			-e TZ=${TZ-`readlink /etc/localtime | sed -e 's,/usr/share/zoneinfo/,,'`} \
			--name $PROJECT_CONTAINER_NAME \
			-d onnimonni/unison:2.48.4 2> /dev/null)
		echo "Waiting $PROJECT_CONTAINER_NAME container to be ready..."
		sleep 5
	fi

	if hash unison 2>/dev/null; then
		echo "Syncing the files. It may take a while if the files are syncing for the first time. Please be patient..."
		SYNCING=$(unison ../ socket://localhost:5000/ \
			-ignore 'Path .git' \
			-ignore 'Path node_modules' \
			-auto -batch 2> /dev/null)

		if hash docker-compose 2>/dev/null; then
			echo "Starting all the containers with docker-compose..."
			
			if [ "$1" == "rebuild" ]; then
				COMPOSE=$(docker-compose up -d --build)
			else
				COMPOSE=$(docker-compose up -d)
			fi
			
			echo "You can now run your app at http://localhost:$WEB_PORT/"
		else
			echo "Please install docker-compose to start your containers..."
		fi

		if hash fswatch 2>/dev/null; then
			echo "Looking for file changes..."
			trap stop_app SIGHUP SIGINT SIGTERM

			SYNCING_CHANGES=$(fswatch -o ../ | xargs -n1 -I{} \
				unison ../ socket://localhost:5000/ \
				-ignore 'Path .git' \
				-ignore 'Path node_modules' \
				-ignore 'Path storage/framework/sessions' \
				-auto -batch)
		else
			"Please install fswatch to keep the changes in your project in sync with the container.."
		fi
	else
		echo "Please install unison..."
	fi
else
	echo "Please install docker..."
fi
