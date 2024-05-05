env           = "dev"
instance_type = "t3.small"
zone_id       = "Z0591896LOE9TNN6GUNS"

#VPC
vpc_cidr_block         = "10.10.0.0/24"
default_vpc_cidr       = "172.31.0.0/16"
default_vpc_id         = "vpc-0e668ae83bd2e62c8"
default_route_table_id = "rtb-089b3d392bb885554"

frontend_subnets   = ["10.10.0.0/27", "10.10.0.32/27"]
backend_subnets    = ["10.10.0.64/27", "10.10.0.96/27"]
db_subnets         = ["10.10.0.128/27", "10.10.0.160/27"]
public_subnets     = ["10.10.0.192/27", "10.10.0.224/27"]
availability_zones = ["us-east-1a", "us-east-1b"]
bastion_nodes      = ["172.31.45.47/32"]
prometheus_nodes   = ["172.31.28.141/32"]
certificate_arn    = "arn:aws:acm:us-east-1:471112738465:certificate/3a4c4ea6-02e0-4af9-8eb8-468d63b1300c"

