resource "aws_vpc" "main" {       # 1. create VPC 
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = local.vpc_final_tags
}

resource "aws_internet_gateway" "main" {  # 2. create internet gateway and attach to VPC
  vpc_id = aws_vpc.main.id  # attach CPC
  tags = local.igw_final_tags    
  
}