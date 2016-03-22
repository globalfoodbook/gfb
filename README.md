# An Wordpress NGINX PHP running inside docker.

A Docker container for setting up Nginx and PHP. This server can respond to requests from any client browser. This best suites development purposes.

This is a sample nginx and php docker container used to test wordpress installation on [http://globalfoodbook.com](http://globalfoodbook.com)


To build this gfb server run the following command:

```bash
$ docker pull globalfoodbook/gfb
```

This will run on a default port of 9292.

To change the PORT for this run the following command:

```bash
$ docker run --name=gfb --detach=true --publish=5118:5118 --publish=80:80 --link=mysql:mysql --link=redis:redis --volume=/path/to/wordpress/:/your/path/to/wp gfb
```

To run the server and expose it on port 9292 of the host machine, run the following command:

```bash
$ docker run --name=gfb --detach=true --publish=5118:5118 --publish=80:80 globalfoodbook/gfb
```

# NB:

## Before pushing to docker hub

## Login

```bash
$ docker login  
```

## Build

```bash
$ cd /to/docker/directory/path/
$ docker build -t <username>/<repo>:latest .
```

## Push to docker hub

```bash
$ docker push <username>/<repo>:latest
```


IP=`docker inspect gfb | grep -w "IPAddress" | awk '{ print $2 }' | head -n 1 | cut -d "," -f1 | sed "s/\"//g"`
HOST_IP=`/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

DOCKER_HOST_IP=`awk 'NR==1 {print $1}' /etc/hosts` # from inside a docker container 
