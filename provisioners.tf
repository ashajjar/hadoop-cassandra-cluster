resource "null_resource" "prepare_hosts_file" {
  provisioner "local-exec" {
    command = "echo '${aws_instance.master-node.private_ip}    master.hadoop.cluster' > \"${path.module}/dns.txt\""
  }

  provisioner "local-exec" {
    command = "echo '${join("\n", formatlist("%v    %v", aws_instance.slave-nodes.*.private_ip, aws_instance.slave-nodes.*.tags.DomainName))}' >> \"${path.module}/dns.txt\""
  }

  provisioner "local-exec" {
    command = "echo '${join("\n", formatlist("%v    %v", aws_instance.cassandra-nodes.*.private_ip, aws_instance.cassandra-nodes.*.tags.DomainName))}' >> \"${path.module}/dns.txt\""
  }
}

resource "null_resource" "admin-node" {
  depends_on = [
  null_resource.prepare_hosts_file]

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

  provisioner "file" {
    source      = "dns.txt"
    destination = "/home/ubuntu/dns.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO ADMIN NODE'",
      "sudo hostnamectl set-hostname manager.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
      "cat /home/ubuntu/dns.txt| sudo tee -a /etc/hosts",
    ]
  }
}

resource "null_resource" "master-node" {
  depends_on = [
  null_resource.prepare_hosts_file]

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

  provisioner "file" {
    source      = "dns.txt"
    destination = "/home/ubuntu/dns.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO MASTER NODE'",
      "sudo hostnamectl set-hostname master.hadoop.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
      "cat /home/ubuntu/dns.txt| sudo tee -a /etc/hosts",
    ]
  }
}

resource "null_resource" "slave-nodes" {
  depends_on = [
  null_resource.prepare_hosts_file]

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

  provisioner "file" {
    source      = "dns.txt"
    destination = "/home/ubuntu/dns.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO SLAVE NODE ${count.index}'",
      "sudo hostnamectl set-hostname slave-${count.index}.hadoop.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
      "cat /home/ubuntu/dns.txt| sudo tee -a /etc/hosts",
    ]
  }
}

resource "null_resource" "cassandra-nodes" {
  depends_on = [
  null_resource.prepare_hosts_file]

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

  provisioner "file" {
    source      = "dns.txt"
    destination = "/home/ubuntu/dns.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO CASSANDRA NODE ${count.index}'",
      "sudo hostnamectl set-hostname node-${count.index}.cassandra.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
      "cat /home/ubuntu/dns.txt| sudo tee -a /etc/hosts",
    ]
  }
}

//resource "null_resource" "write_resource_cluster_member_ip_addresses" {
//  depends_on = ["aws_instance.cluster_member"]
//
//  provisioner "local-exec" {
//    command = "echo '${join("\n", formatlist("instance=%v ; private=%v ; public=%v", aws_instance.cluster_member.*.id, aws_instance.cluster_member.*.private_ip, aws_instance.cluster_member.*.public_ip))}' | awk '{print \"node=${var.cluster_member_name_prefix}\" NR-1 \" ; \" $0}' > \"${path.module}/cluster_ips.txt\""
//    # Outputs is:
//    # node=cluster-node-0 ; instance=i-03b1f460318c2a1c3 ; private=10.0.1.245 ; public=35.180.50.32
//    # node=cluster-node-1 ; instance=i-05606bc6be9639604 ; private=10.0.1.198 ; public=35.180.118.126
//    # node=cluster-node-2 ; instance=i-0931cbf386b89ca4e ; private=10.0.1.153 ; public=35.180.50.98
//  }
//// And, with the following shell command I can add them to my local /etc/hosts file:
//// awk -F'[;=]' '{ print $8 " " $2 " #" $4 }' cluster_ips.txt >> /etc/hosts
//
//}
