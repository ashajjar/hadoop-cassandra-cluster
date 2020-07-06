variable "aws_profile" {
  default = "default"
}
variable "region" {}
variable "slaves-count" {}
variable "cassandra-nodes-count" {}
variable "source_ami" {}
variable "instance_type" {}
variable "vpc_cidr" {}
variable "vpc_cidrs" {}
variable "load-hadoop" {}
variable "manager_instance_type" {}
variable "hadoop_master_instance_type" {}
variable "hadoop_slave_instance_type" {}
variable "cassandra_node_instance_type" {}