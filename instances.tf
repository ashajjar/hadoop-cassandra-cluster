resource "aws_instance" "admin-node" {
  key_name               = aws_key_pair.cluster_key.key_name
  ami                    = var.source_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.default_egress.id, aws_security_group.admin_access_public.id, aws_security_group.admin_access_private.id]
  subnet_id              = aws_subnet.public_subnet.id

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("keys/cluster_key")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  tags = {
    Name = "Cluster Manager"
  }
}

resource "aws_instance" "master-node" {
  key_name      = aws_key_pair.cluster_key.key_name
  ami           = var.source_ami
  instance_type = var.instance_type

  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.default_egress.id, aws_security_group.admin_access_private.id]
  subnet_id                   = aws_subnet.private_subnet.id

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = self.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO MASTER NODE'",
      "sudo hostnamectl set-hostname master.hadoop.cluster"
    ]
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  tags = {
    Name = "Hadoop-Master"
  }
}

resource "aws_instance" "slave-nodes" {
  key_name      = aws_key_pair.cluster_key.key_name
  ami           = var.source_ami
  instance_type = var.instance_type
  count         = var.slaves-count

  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.default_egress.id, aws_security_group.admin_access_private.id]
  subnet_id                   = aws_subnet.private_subnet.id

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = self.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO SLAVE NODE ${count.index}'",
      "sudo hostnamectl set-hostname slave-${count.index}.hadoop.cluster"
    ]
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  tags = {
    Name = "Hadoop-Slave-${count.index}"
  }
}

resource "aws_instance" "cassandra-nodes" {
  key_name      = aws_key_pair.cluster_key.key_name
  ami           = var.source_ami
  instance_type = var.instance_type
  count         = var.cassandra-nodes-count

  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.default_egress.id, aws_security_group.admin_access_private.id]
  subnet_id                   = aws_subnet.private_subnet.id


  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = self.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO CASSANDRA NODE ${count.index}'",
      "sudo hostnamectl set-hostname node-${count.index}.cassandra.cluster"
    ]
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  tags = {
    Name = "Cassandra-Node-${count.index}"
  }
}