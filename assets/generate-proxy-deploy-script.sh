#!/usr/bin/env bash

registry="hortonworks"
flavor=$(cat sandbox-flavor)
if [ "$flavor" == "hdf" ]; then
 hdfEnabled=true
 hdpEnabled=false
elif [ "$flavor" == "hdp" ]; then
 hdfEnabled=false
 hdpEnabled=true
fi

# Set the value to 'true' if the sandbox will be running on the VM.
# 'false' otherwise.
#
# Ex: sed -i 's/hdfEnabled=true/hdfEnabled=true/g' /sandbox/proxy/generate-proxy-deploy-script.sh

# In the case of HTTP, requests pass along the hostname the user intended to
# make a request against.  For this reason, we can distinguish what sandbox
# a request was intended for based on the content of the hostname and do can
# safely route all external HTTP-bound ports to each internal container.
#
# HDF ports: (1080 4200 7777 7788 8000 8080 8744 8886 9088 61080 61888 8585 3000)
# HDP ports: (4040 6080 8042 8088 8188 8198 8886 8888 9995 11000 15000 16010 18081 19888 21000 50070 50075 50111 10002 30800)
httpPorts=(1080 4200 7777 7788 8000 8080 8443 8744 8886 9088 9089 61080 61888 4040 6080 8042 8088 8188 8198 8888 9995 11000 15000 16010 18081 19888 21000 50070 50075 50111 8081 8585 3000 10002 30800)

# In the case of TCP/UDP ports, we can not filter incoming connections on
# hostname, and so must then have 1-to-1 mappings from EXTERNAL_PORTs to
# INTERNAL_PORTs.
#
# Use the following format:
# [EXTERNAL_PORT]=INTERNAL_PORT
#
# Notes:
#   ports 2200/2122 are used to SSH into the host VM
#   2181 on HDF <- 2182
#
tcpPortsHDF=(
[2202]=22
[2182]=2181
[4557]=4557
[6627]=6627
[6667]=6667
[9090]=9090
[9091]=9091
[15500]=15500
)

tcpPortsHDP=(
[12049]=2049
[2201]=22
[2222]=22
[1100]=1100
[1111]=1111
[12200]=1220
[1988]=1988
[2100]=2100
[2181]=2181
[4242]=4242
[5007]=5007
[5011]=5011
[6001]=6001
[6003]=6003
[6008]=6008
[6188]=6188
[6668]=6667
[8005]=8005
[8020]=8020
[8032]=8032
[8040]=8040
[8082]=8082
[8086]=8086
[8090]=8090
[8091]=8091
[8765]=8765
[8889]=8889
[8983]=8983
[8993]=8993
[9000]=9000
[9996]=9996
[10000]=10000
[10001]=10001
[10015]=10015
[10016]=10016
[10500]=10500
[10502]=10502
[15002]=15002
[16000]=16000
[16020]=16020
[16030]=16030
[18080]=18080
[33553]=33553
[39419]=39419
[42111]=42111
[50079]=50079
[50095]=50095
[60000]=60000
[60080]=60080
)

######################################################################
########### No changes should be needed beyond this point. ###########
######################################################################



# Clear conf files and then recreate necessary directories
rm -rf sandbox
mkdir -p sandbox/proxy/conf.d
mkdir -p sandbox/proxy/conf.stream.d


if [ "$hdfEnabled" = true ]; then
  name="sandbox-hdf-standalone-cda-ready"
  hostname="sandbox-hdf.hortonworks.com"
  for port in ${httpPorts[@]}; do
    cat << EOF >> sandbox/proxy/conf.d/http-hdf.conf
server {
  listen $port;
  server_name $hostname;
  location / {
    proxy_pass http://$name:$port;
  }
}
EOF
  done

  for origin in "${!tcpPortsHDF[@]}"; do
    cat << EOF >> sandbox/proxy/conf.stream.d/tcp-hdf.conf
server {
  proxy_timeout 60m;
  listen $origin;
  proxy_pass $name:${tcpPortsHDF[$origin]};
}
EOF
  done
fi

if [ "$hdpEnabled" = true ]; then
 name="sandbox-hdp-security"
 hostname="sandbox-hdp.hortonworks.com"
 cat << EOF >> sandbox/proxy/conf.d/http-hdp.conf
map \$http_upgrade \$connection_upgrade {
 default upgrade;
 '' close;
}
EOF
  for port in ${httpPorts[@]}; do
   if [ $port == '9995' ]; then
    cat << EOF >> sandbox/proxy/conf.d/http-hdp.conf
server {
  listen 9995;
  server_name sandbox-hdp.hortonworks.com;
  location / {
    proxy_pass http://sandbox-hdp-security:9995;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;
  }
}
EOF
else
 cat << EOF >> sandbox/proxy/conf.d/http-hdp.conf
server {
  listen $port;
  server_name $hostname;
  location / {
    proxy_pass http://$name:$port;
  }
}
EOF
fi
  done

  for origin in "${!tcpPortsHDP[@]}"; do
   if [ $origin == '2201' ] || [ $origin == '2202' ]; then
    cat << EOF >> sandbox/proxy/conf.stream.d/tcp-hdp.conf
server {
  listen $origin;
  proxy_timeout 60m;
  proxy_pass $name:${tcpPortsHDP[$origin]};
}
EOF
  else
    cat << EOF >> sandbox/proxy/conf.stream.d/tcp-hdp.conf
server {
  listen $origin;
  proxy_pass $name:${tcpPortsHDP[$origin]};
}
EOF
  fi
  done
fi


# Generate the appropriate 'docker run' command by finding all ports to expose
# (found in the above lists).

absPath=$(pwd)
version=$(docker images | grep ${registry}/sandbox-proxy  | awk '{print $2}');
cat << EOF > sandbox/proxy/proxy-deploy.sh
#!/usr/bin/env bash
docker rm -f sandbox-proxy 2>/dev/null
docker run --name sandbox-proxy --network=cda \\
-v $absPath/assets/nginx.conf:/etc/nginx/nginx.conf \\
-v $absPath/sandbox/proxy/conf.d:/etc/nginx/conf.d \\
-v $absPath/sandbox/proxy/conf.stream.d:/etc/nginx/conf.stream.d \\
EOF

for port in ${httpPorts[@]}; do
  cat << EOF >> sandbox/proxy/proxy-deploy.sh
-p $port:$port \\
EOF
done
for port in ${!tcpPortsHDF[@]}; do
  cat << EOF >> sandbox/proxy/proxy-deploy.sh
-p $port:$port \\
EOF
done
for port in ${!tcpPortsHDP[@]}; do
  cat << EOF >> sandbox/proxy/proxy-deploy.sh
-p $port:$port \\
EOF
done

cat << EOF >> sandbox/proxy/proxy-deploy.sh
-d ${registry}/sandbox-proxy:$version
EOF
