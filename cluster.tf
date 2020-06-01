provider "aws" {
  profile = "cccp_user"
  region  = var.region
}

resource "aws_key_pair" "cluster_key" {
  key_name   = "cluster_key"
  public_key = file("keys/cluster_key.pub")
}

resource "aws_vpc" "ClusterVPC" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "ClusterSubnet" {
  cidr_block = "10.0.0.0/16"
  vpc_id     = aws_vpc.ClusterVPC.id
}
#Ubuntu Server 18.04 LTS (HVM), SSD Volume Type
resource "aws_instance" "admin-node" {
  key_name      = aws_key_pair.cluster_key.key_name
  ami           = "ami-0e342d72b12109f91"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ClusterSubnet.id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("keys/cluster_key")
    host        = self.public_ip
  }

  tags = {
    Name = "Cluster Manager"
  }
}

#bitnami-hadoop-2.7.2-0-linux-ubuntu-14.04.3-x86_64-hvm-ebs (ami-93a148fc)
resource "aws_instance" "master-node" {
  key_name                    = aws_key_pair.cluster_key.key_name
  ami                         = "ami-93a148fc"
  instance_type               = "t2.micro"
  private_ip                  = "10.0.1.100"
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.ClusterSubnet.id

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = self.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "remote-exec" {
    inline = ["echo 'CONNECTED TO MASTER NODE'"]
  }

  tags = {
    Name = "Hadoop-Master"
  }
}

#bitnami-hadoop-2.7.2-0-linux-ubuntu-14.04.3-x86_64-hvm-ebs (ami-93a148fc)
resource "aws_instance" "slave-nodes" {
  key_name                    = aws_key_pair.cluster_key.key_name
  ami                         = "ami-93a148fc"
  instance_type               = "t2.micro"
  private_ip                  = "10.0.1.${count.index + 1}"
  associate_public_ip_address = false
  count                       = var.slaves-count
  subnet_id                   = aws_subnet.ClusterSubnet.id

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = self.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "remote-exec" {
    inline = ["echo 'CONNECTED TO SLAVE NODE ${count.index}'"]
  }

  tags = {
    Name = "Hadoop-Slave-${count.index}"
  }
}

#bitnami-cassandra-3.10-0-linux-ubuntu-14.04.3-x86_64-hvm-ebs (ami-6e598c01)
resource "aws_instance" "cassandra-nodes" {
  key_name                    = aws_key_pair.cluster_key.key_name
  ami                         = "ami-6e598c01"
  instance_type               = "t2.micro"
  private_ip                  = "10.0.2.${count.index + 1}"
  associate_public_ip_address = false
  count                       = var.cassandra-nodes-count
  subnet_id                   = aws_subnet.ClusterSubnet.id

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = self.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "remote-exec" {
    inline = ["echo 'CONNECTED TO CASSANDRA NODE ${count.index}'"]
  }

  tags = {
    Name = "Cassandra-Node-${count.index}"
  }
}