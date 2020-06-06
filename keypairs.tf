resource "aws_key_pair" "cluster_key" {
  key_name   = "cluster_key"
  public_key = file("keys/cluster_key.pub")
}
