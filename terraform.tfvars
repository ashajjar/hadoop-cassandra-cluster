region                = "eu-central-1"
load-hadoop           = true
slaves-count          = 3
cassandra-nodes-count = 3 # to prevent Cassandra from loading set this to ZERO
source_ami            = "ami-0e342d72b12109f91" #Ubuntu Server 18.04 LTS (HVM), SSD Volume Type
instance_type         = "t2.micro"
vpc_cidr              = "172.31.0.0/16"
vpc_cidrs             = "172.31.0.0/20,172.31.16.0/20,172.31.32.0/20,172.31.48.0/20"