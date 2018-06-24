#!/usr/bin/env bash
set -e


# Setup the consul init scripts
cat <<EOF >/tmp/consul_upstart
description "Consul Agent"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

script
  if [ -f "/etc/service/consul" ]; then
    . /etc/service/consul
  fi

  # Make sure to use all our CPUs, because Vault can block a scheduler thread
  export GOMAXPROCS=`nproc`
  BIND=`ifconfig eth0 | grep "inet addr" | awk '{ print substr($$2,6) }'`
  exec /usr/local/bin/consul agent \
    -join=${consul_cluster} \
    -bind=\$${BIND} \
    -config-dir="/etc/consul.d" \
    -data-dir=/opt/consul/data \
    -client 0.0.0.0 \
    >>/var/log/consul.log 2>&1
end script
EOF
sudo mv /tmp/consul_upstart /etc/init/consul.conf


# configure nomad to listen on private ip address for rpc and serf
local_ipv4=`ifconfig eth0 | grep "inet addr" | awk '{ print substr($$2,6) }'`
echo "advertise {
  http = \"$${local_ipv4}\"
  rpc = \"$${local_ipv4}\"
  serf = \"$${local_ipv4}\"
}" | tee -a /etc/nomad.d/nomad-default.hcl

# setup nomad client
if [ "${nomad_client}" == "true" ]
then
cat <<EOF> /etc/nomad.d/nomad-client.hcl
client {
  enabled         = true
  client_max_port = 15000
  datacenter = "${nomad_datacenter}"
  options {
    "user.blacklist" = ""
    "docker.cleanup.image"   = "0"
    "driver.raw_exec.enable" = "1"
  }
}
EOF
fi


# setup nomad server
if [ "${nomad_server}" == "true" ]
then
cat <<EOF> /etc/nomad.d/nomad-server.hcl
data_dir = "/etc/nomad.d"

server {
  enabled          = true
  bootstrap_expect = ${servers}
}
EOF
fi


cat <<EOF > /etc/nomad.d/nomad-vault.hcl
vault {
  enabled = true
  address = "${vault_cluster}"
  token = "${vault_token}"
}
EOF

# start nomad once it is configured correctly
mkdir /opt/consul/
sudo start consul
sudo start nomad




