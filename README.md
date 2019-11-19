# Hortonworks HDP Sandbox on Docker
The Hortonworks HDP Sandbox is a straightforward, pre-configured, learning environment that contains the latest developments from Apache Hadoop, specifically the Hortonworks Data Platform (HDP). It allows you to learn and explore HDP on your own.

# Deploying Hortonworks Sandbox on Docker
This guide walks through the general approach for installing the Hortonworks Sandbox HDP onto Docker on your computer.

## Prerequisites
  * Docker Installed, version 17.09 or newer
  * A computer with minimum 10 GB RAM dedicated to the container

## Deploy HDP Sandbox
From the command line run the script:

```bash
cd /path/to/script
sh docker-deploy-{HDPversion}.sh
```

> Note: You only need to run script once. It will setup and start the sandbox for you, creating the sandbox docker container in the process if necessary.

The script output will be similar to:

```bash
$ ./docker-deploy-hdp30.sh 
+ registry=hortonworks
+ name=sandbox-hdp
+ version=3.0.1
+ proxyName=sandbox-proxy
+ proxyVersion=1.0
+ flavor=hdp
+ echo hdp
+ mkdir -p sandbox/proxy/conf.d
+ mkdir -p sandbox/proxy/conf.stream.d
+ docker pull hortonworks/sandbox-hdp:3.0.1
3.0.1: Pulling from hortonworks/sandbox-hdp
Digest: sha256:7b767af7b42030fb1dd0f672b801199241e6bef1258e3ce57361edb779d95921
Status: Image is up to date for hortonworks/sandbox-hdp:3.0.1
docker.io/hortonworks/sandbox-hdp:3.0.1
+ docker pull hortonworks/sandbox-proxy:1.0
1.0: Pulling from hortonworks/sandbox-proxy
Digest: sha256:42e4cfbcbb76af07e5d8f47a183a0d4105e65a1e7ef39fe37ab746e8b2523e9e
Status: Image is up to date for hortonworks/sandbox-proxy:1.0
docker.io/hortonworks/sandbox-proxy:1.0
+ '[' hdp = hdf ']'
+ '[' hdp = hdp ']'
+ hostname=sandbox-hdp.hortonworks.com
++ docker images
++ grep hortonworks/sandbox-hdp
++ awk '{print $2}'
+ version=3.0.1
+ docker network create cda
0bb1cf34faa63def4209cd7b1cf4ca0fb54e761f6b17dbbb33c7bb0c25d9cfa0
+ docker run -d --name sandbox-hdp -h sandbox-hdp.hortonworks.com --network=cda --network-alias=sandbox-hdp.hortonworks.com --security-opt apparmor:unconfined --cap-add SYS_ADMIN --mount type=bind,source=/run/user/1000/bus,target=/run/user/1000/bus --mount type=bind,source=/run/dbus/system_bus_socket,target=/run/dbus/system_bus_socket --env=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus hortonworks/sandbox-hdp:3.0.1
3d814adfeabd08c6a78ec90b5f580ba0931a8575d2036237f06ecbb4dce75a98
+ echo ' Remove existing postgres run files. Please wait'
 Remove existing postgres run files. Please wait
+ sleep 2
+ docker exec -t sandbox-hdp sh -c 'rm -rf /var/run/postgresql/*; systemctl restart postgresql-9.6.service;'
+ sed s/sandbox-hdp-security/sandbox-hdp/g assets/generate-proxy-deploy-script.sh
+ mv -f assets/generate-proxy-deploy-script.sh.new assets/generate-proxy-deploy-script.sh
+ chmod +x assets/generate-proxy-deploy-script.sh
+ assets/generate-proxy-deploy-script.sh
+ uname
+ grep MINGW
+ chmod +x sandbox/proxy/proxy-deploy.sh
+ sandbox/proxy/proxy-deploy.sh
f05b4fa15f2c2f34ed3be5660f33700fa7ed6ee35bdb6c5d595b83df9561c100
```

## Verify HDP Sandbox
Verify HDP sandbox was deployed successfully by issuing the command:

```bash
docker ps
```

You should see something like:

```bash
CONTAINER ID        IMAGE                           COMMAND                  CREATED             STATUS              PORTS                         NAMES
f05b4fa15f2c        hortonworks/sandbox-proxy:1.0   "nginx -g 'daemon of…"   17 seconds ago      Up 13 seconds       ...                           sandbox-proxy
3d814adfeabd        hortonworks/sandbox-hdp:3.0.1   "/usr/sbin/init"         4 minutes ago       Up 4 minutes        22/tcp, 4200/tcp, 8080/tcp    sandbox-hdp
```

## Stop HDP Sandbox
When you want to stop/shutdown your HDP sandbox, run the following commands:

```bash
docker stop sandbox-hdp
docker stop sandbox-proxy
```

## Restart HDP Sandbox
When you want to re-start your sandbox, run the following commands:

```bash
docker start sandbox-hdp
docker start sandbox-proxy
```

## Remove HDP Sandbox
A container is an instance of the Sandbox image. You must **stop** container dependancies before removing it. Issue the following commands:

```bash
docker
docker
docker
docker
stop sandbox-hdp
stop sandbox-proxy
rm sandbox-hdp
rm sandbox-proxy
```

If you want to remove the HDP Sandbox image, issue the following command after stopping and removing the containers:

```bash
docker rmi hortonworks/sandbox-hdp:{release}
```