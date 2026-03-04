resource "aws_vpc" "main" {       # 1. create VPC 
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = local.vpc_final_tags
}

resource "aws_internet_gateway" "main" {  # 2. create internet gateway and attach to VPC
  vpc_id = aws_vpc.main.id  # attach VPC
  tags = local.igw_final_tags    
  
}

# 3. subnet creation
resource "aws_subnet" "main" {   
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge (
         local.common_tags ,
         { # roboshop-dev-public-us-east-1a
           Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
         },
         var.public_subnet_tags 
     )
   
  }