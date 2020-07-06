#!/usr/bin/env bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install openjdk-8-jdk -y

cd ~ || exit 1

echo "deb https://downloads.apache.org/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
curl https://downloads.apache.org/cassandra/KEYS | sudo apt-key add -
sudo apt-key adv --keyserver pool.sks-keyservers.net --recv-key A278B781FE4B2BDA

sudo apt-get update
sudo apt-get install cassandra -y

sudo service cassandra stop

tar -xf cassandra-config.tar.gz

ALL_NODES_IPS=$(cat /home/ubuntu/nodes.ips)
THIS_NODE_IP=$(cat /home/ubuntu/node.ip)
sudo cp -rf /home/ubuntu/cassandra-config/* /etc/cassandra/
sudo sed -i "s/- seeds:.*/- seeds: \"$ALL_NODES_IPS\"/g" /etc/cassandra/cassandra.yaml
sudo sed -i "s/listen_address:.*/listen_address: $THIS_NODE_IP/g" /etc/cassandra/cassandra.yaml
sudo sed -i "s/rpc_address:.*/rpc_address: $THIS_NODE_IP/g" /etc/cassandra/cassandra.yaml
sudo service cassandra start
