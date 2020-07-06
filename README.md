# HCCIaC - Hadoop and Cassandra Cluster Infrastructure as Code (IaC)

DISCLAIMER:
RUNNING THE CODE IN THIS REPO MAY COST REAL MONEY

## Configuring Hadoop
Anything you add in `hadoop-config/` directory will be copied as it is to Hadoop's configuration directory : `/home/ubuntu/hadoop/etc/hadoop/` 

The basic configuration of hadoop is done in these files :

* [core-site.xml](hadoop-config/core-site.xml)
* [hdfs-site.xml](hadoop-config/hdfs-site.xml)
* [mapred-site.xml](hadoop-config/mapred-site.xml)
* [yarn-site.xml](hadoop-config/yarn-site.xml)
* [workers](hadoop-config/workers)
* [slaves](hadoop-config/slaves)

## Configuring Cassandra
Anything you add in `cassandra-config/` directory will be copied as it is to Cassandra's configuration directory : `/etc/cassandra/` 

Basic configuration of cassandra is done in this file:
* [cassandra.yaml](cassandra-config/cassandra.yaml)

## Before You Run

1. Create a directory call `keys/`
2. Create a key pair called `cluster_key` (`cluster_key`,`cluster_key.pub`)

An alternative would be to create a symilink to the keys you have like so:
```shell script
ln -s ~/.ssh/id_rsa.pub keys/cluster_key.pub
ln -s ~/.ssh/id_rsa keys/cluster_key
```

These keys will be your keys to access AWS EC2 instances.

## How to Run

Simply run the following command :
```shell script
terraform apply
```

The following command will apply the infrastructure without approval request and will save the output to a file for later debugging if necessary.
```shell script
terraform apply -auto-approve 2>&1 | tee log-$(date '+%Y-%m-%d_%H-%M-%S').out
```


## How to Access the Cluster

After terraform applies the infrastructure successfully you can run the following to access the Admin Node

```shell script
ssh -i keys/cluster_key ubuntu@$(terraform output manager-ip)
``` 

To access the cluster's web UI (Like HDFS and Yarn) you can use SSH with local forwarding, like so:
```shell script
ssh -L 50070:master.hadoop.cluster:50070 -i keys/cluster_key ubuntu@$(terraform output manager-ip)
``` 
Then you can access these services on localhost like [HDFS](http://localhost:50070/) and [Yarn](http://localhost:8088/)

## How to Stop the Cluster

Run this command with caution and at your own risk this will destroy the cluster without your confirmation:
```shell script
terraform destroy -auto-approve
```