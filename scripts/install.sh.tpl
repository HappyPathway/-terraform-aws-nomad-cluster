#!/usr/bin/env bash
set -e

# Setup the configuration
#consul conf
hostname=$$(hostname)
ip_address=$$(ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')

cat << EOF > /etc/consul.d/consul-join.hcl
{
    "retry_join": ["provider=aws tag_key=ConsulServer tag_value=${env}"]
}
EOF

cat << EOF > /etc/consul.d/consul-type.json
{
  "server": false
}
EOF

cat << EOF > /etc/consul.d/consul-node.json
{
  "advertise_addr": "$${ip_address}",
  "node_name": "$${hostname}"
}
EOF

cat << EOF > /etc/consul.d/consul-datacenter.json
{
  "datacenter": "${consul_datacenter}"
}
EOF

# configure nomad to listen on private ip address for rpc and serf
cat << EOF > /etc/nomad.d/nomad-default.hcl
advertise {
  http = "$${ip_address}"
  rpc = "$${ip_address}"
  serf = "$${ip_address}"
}
EOF

# setup nomad client
if [ "${nomad_client}" == "true" ]
then
cat <<EOF> /etc/nomad.d/nomad-client.hcl
data_dir = "/opt/nomad"
client {
  enabled         = true
  client_max_port = 15000
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
export CONSUL_HTTP_ADDR=http://127.0.0.1:8500
echo 'export CONSUL_HTTP_ADDR=http://127.0.0.1:8500' > /etc/profile.d/consul.sh

# Start Consul
sudo stop consul
sudo start consul
until consul members; do echo "Consul Not Ready" && sleep 10; done


# Start Nomad
sudo stop nomad || echo 
sudo start nomad || echo
until lsof -i:4646; do echo "Nomad Not Ready" && sleep 10; done

