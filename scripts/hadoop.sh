#!/usr/bin/env bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install openjdk-8-jdk -y
cd /usr/lib/jvm || exit 1
sudo mv java-8-openjdk-amd64 jdk
mkdir -p /home/ubuntu/data/hdfs/namenode
mkdir -p /home/ubuntu/data/hdfs/datanode

cd ~ || exit 1

echo "Host *" > .ssh/config
echo " StrictHostKeyChecking no" >> .ssh/config

sudo tar -xf hadoop.tar.gz
sudo rm hadoop.tar.gz

sudo chown -R ubuntu:ubuntu /home/ubuntu/hadoop

printf "
export JAVA_HOME=/usr/lib/jvm/jdk
export HADOOP_HOME=/home/ubuntu/hadoop
export PATH=\${PATH}:\${HADOOP_HOME}/bin:\${HADOOP_HOME}/sbin

export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_HOME/lib/native\"
" >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc


