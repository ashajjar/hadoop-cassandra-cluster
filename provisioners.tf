resource "null_resource" "prepare_hadoop_dns_and_config" {
  count = (var.load-hadoop ? 1 : 0)

  provisioner "local-exec" {
    command = "echo '${aws_instance.master-node.0.private_ip}    master.hadoop.cluster' > \"${path.module}/dns.txt\""
  }

  provisioner "local-exec" {
    command = "echo '${join("\n", formatlist("%v    %v", aws_instance.slave-nodes.*.private_ip, aws_instance.slave-nodes.*.tags.DomainName))}' >> \"${path.module}/dns.txt\""
  }

  provisioner "local-exec" {
    command = "echo '${join("\n", formatlist("%v    %v", aws_instance.cassandra-nodes.*.private_ip, aws_instance.cassandra-nodes.*.tags.DomainName))}' >> \"${path.module}/dns.txt\""
  }

  provisioner "local-exec" {
    command = "echo '${join("\n", formatlist("%v", aws_instance.slave-nodes.*.tags.DomainName))}' > hadoop-config/workers"
  }

  provisioner "local-exec" {
    command = "echo '${join("\n", formatlist("%v", aws_instance.slave-nodes.*.tags.DomainName))}' > hadoop-config/slaves"
  }

  provisioner "local-exec" {
    command = "tar -czf hadoop-config.tar.gz hadoop-config/"
  }
}

resource "null_resource" "prepare_cassandra_dns_and_config" {
  depends_on = [
    null_resource.prepare_hadoop_dns_and_config,
  ]
  provisioner "local-exec" {
    command = "echo '${join("\n", formatlist("%v    %v", aws_instance.cassandra-nodes.*.private_ip, aws_instance.cassandra-nodes.*.tags.DomainName))}' >> \"${path.module}/dns.txt\""
  }

  provisioner "local-exec" {
    command = "tar -czf cassandra-config.tar.gz cassandra-config/"
  }
}

resource "null_resource" "admin-node" {
  depends_on = [
    null_resource.prepare_hadoop_dns_and_config,
    null_resource.prepare_cassandra_dns_and_config
  ]

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
    source      = "keys/cluster_key.pub"
    destination = "/home/ubuntu/.ssh/id_rsa.pub"
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
      "sudo chmod 644 /home/ubuntu/.ssh/id_rsa.pub",
      "cat /home/ubuntu/dns.txt | sudo tee -a /etc/hosts",
    ]
  }
}

resource "null_resource" "master-node" {
  count = (var.load-hadoop ? 1 : 0)
  depends_on = [
    null_resource.prepare_hadoop_dns_and_config
  ]

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = aws_instance.master-node.0.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "file" {
    source      = "keys/cluster_key"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "file" {
    source      = "keys/cluster_key.pub"
    destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source      = "dns.txt"
    destination = "/home/ubuntu/dns.txt"
  }

  provisioner "file" {
    source      = "hadoop-config.tar.gz"
    destination = "/home/ubuntu/hadoop-config.tar.gz"
  }

  provisioner "file" {
    source      = "scripts/hadoop.sh"
    destination = "/tmp/hadoop.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO MASTER NODE'",
      "sudo hostnamectl set-hostname master.hadoop.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
      "sudo chmod 644 /home/ubuntu/.ssh/id_rsa.pub",
      "cat /home/ubuntu/dns.txt | sudo tee -a /etc/hosts",
      "echo 'Host *' > .ssh/config",
      "echo ' StrictHostKeyChecking no' >> .ssh/config",
      "wget --trust-server-names $(curl 'https://www.apache.org/dyn/closer.cgi' | grep -o '<strong>[^<]*</strong>' | sed 's/<[^>]*>//g' | head -1)\"hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz\" -O /home/ubuntu/hadoop-2.7.7.tar.gz",
      "sudo chmod +x /tmp/hadoop.sh",
      "/tmp/hadoop.sh",
    ]
  }
}

resource "null_resource" "slave-nodes" {
  depends_on = [
    null_resource.master-node,
  ]

  count = (var.load-hadoop ? 1 : 0) * var.slaves-count

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
    source      = "keys/cluster_key.pub"
    destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source      = "dns.txt"
    destination = "/home/ubuntu/dns.txt"
  }

  provisioner "file" {
    source      = "scripts/hadoop.sh"
    destination = "/tmp/hadoop.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO SLAVE NODE ${count.index}'",
      "sudo hostnamectl set-hostname slave-${count.index}.hadoop.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
      "sudo chmod 644 /home/ubuntu/.ssh/id_rsa.pub",
      "cat /home/ubuntu/dns.txt | sudo tee -a /etc/hosts",
      "echo 'Host *' > .ssh/config",
      "echo ' StrictHostKeyChecking no' >> .ssh/config",
      "scp master.hadoop.cluster:/home/ubuntu/hadoop-2.7.7.tar.gz /home/ubuntu/hadoop-2.7.7.tar.gz",
      "scp master.hadoop.cluster:/home/ubuntu/hadoop-config.tar.gz /home/ubuntu/hadoop-config.tar.gz",
      "sudo chmod +x /tmp/hadoop.sh",
      "/tmp/hadoop.sh",
    ]
  }
}

resource "null_resource" "start-hadoop" {
  count = (var.load-hadoop ? 1 : 0)
  depends_on = [
    null_resource.master-node,
    null_resource.slave-nodes
  ]

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = aws_instance.master-node.0.private_ip
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'STARTING HADOOP ...'",
      "/home/ubuntu/hadoop/bin/hdfs namenode -format",
      "/home/ubuntu/hadoop/sbin/start-dfs.sh",
      "/home/ubuntu/hadoop/sbin/start-yarn.sh",
      "/home/ubuntu/hadoop/sbin/mr-jobhistory-daemon.sh start historyserver",
      "sleep 30",
      "/home/ubuntu/hadoop/bin/hdfs dfsadmin -report",
      "/home/ubuntu/hadoop/bin/yarn node -list",
    ]
  }
}

resource "null_resource" "cassandra-nodes" {
  depends_on = [
    null_resource.prepare_cassandra_dns_and_config
  ]

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
    source      = "keys/cluster_key.pub"
    destination = "/home/ubuntu/.ssh/id_rsa.pub"
  }

  provisioner "file" {
    source      = "dns.txt"
    destination = "/home/ubuntu/dns.txt"
  }

  provisioner "file" {
    source      = "cassandra-config.tar.gz"
    destination = "/home/ubuntu/cassandra-config.tar.gz"
  }

  provisioner "file" {
    source      = "scripts/cassandra.sh"
    destination = "/tmp/cassandra.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CONNECTED TO CASSANDRA NODE ${count.index}'",
      "sudo hostnamectl set-hostname node-${count.index}.cassandra.cluster",
      "sudo chmod 400 /home/ubuntu/.ssh/id_rsa",
      "sudo chmod 644 /home/ubuntu/.ssh/id_rsa.pub",
      "cat /home/ubuntu/dns.txt | sudo tee -a /etc/hosts",
      "echo 'Host *' > .ssh/config",
      "echo ' StrictHostKeyChecking no' >> .ssh/config",
      "echo '${join(",", formatlist("%v", aws_instance.cassandra-nodes.*.private_ip))}' > /home/ubuntu/nodes.ips",
      "echo '${element(aws_instance.cassandra-nodes.*.private_ip, count.index)}' > /home/ubuntu/node.ip",
      "sudo chmod +x /tmp/cassandra.sh",
      "/tmp/cassandra.sh",
    ]
  }
}


resource "null_resource" "check-cassandra" {
  depends_on = [
    null_resource.cassandra-nodes
  ]

  connection {
    bastion_host = aws_instance.admin-node.public_ip
    host         = element(aws_instance.cassandra-nodes.*.private_ip, 0)
    user         = "ubuntu"
    private_key  = file("keys/cluster_key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'CHECKING CASSANDRA ...'",
      "sleep 30",
      "nodetool enablethrift",
      "nodetool status",
      "nodetool describecluster"
    ]
  }
}