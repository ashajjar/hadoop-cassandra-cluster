resource "null_resource" "admin-node" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("keys/cluster_key")
    host        = aws_instance.admin-node.public_ip
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO ADMIN NODE'",
      "sudo hostnamectl set-hostname manager.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
    ]
  }
}

resource "null_resource" "master-node" {
  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = aws_instance.master-node.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO MASTER NODE'",
      "sudo hostnamectl set-hostname master.hadoop.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
    ]
  }
}

resource "null_resource" "slave-nodes" {
  count = var.slaves-count

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = element(aws_instance.slave-nodes.*.private_ip, count.index)
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO SLAVE NODE ${count.index}'",
      "sudo hostnamectl set-hostname slave-${count.index}.hadoop.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
    ]
  }
}

resource "null_resource" "cassandra-nodes" {
  count = var.cassandra-nodes-count

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = element(aws_instance.cassandra-nodes.*.private_ip, count.index)
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO CASSANDRA NODE ${count.index}'",
      "sudo hostnamectl set-hostname node-${count.index}.cassandra.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
    ]
  }
}