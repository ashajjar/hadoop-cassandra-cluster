resource "aws_instance" "admin-node" {
  key_name               = aws_key_pair.cluster_key.key_name
  ami                    = var.source_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.default_egress.id, aws_security_group.admin_access_public.id, aws_security_group.admin_access_private.id]
  subnet_id              = aws_subnet.public_subnet.id

  tags = {
    Name = "Cluster Manager"
  }
}

resource "aws_instance" "master-node" {
  count         = var.load-hadoop ? 1 : 0
  key_name      = aws_key_pair.cluster_key.key_name
  ami           = var.source_ami
  instance_type = var.instance_type

  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.default_egress.id, aws_security_group.admin_access_private.id]
  subnet_id                   = aws_subnet.private_subnet.id

  tags = {
    Name = "Hadoop-Master"
  }
}

resource "aws_instance" "slave-nodes" {
  key_name      = aws_key_pair.cluster_key.key_name
  ami           = var.source_ami
  instance_type = var.instance_type
  count         = (var.load-hadoop ? 1 : 0) * var.slaves-count

  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.default_egress.id, aws_security_group.admin_access_private.id]
  subnet_id                   = aws_subnet.private_subnet.id

  tags = {
    Name       = "Hadoop-Slave-${count.index}"
    DomainName = "slave-${count.index}.hadoop.cluster"
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

  tags = {
    Name       = "Cassandra-Node-${count.index}"
    DomainName = "node-${count.index}.cassandra.cluster"
  }
}