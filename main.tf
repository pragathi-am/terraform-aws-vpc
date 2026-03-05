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
# public subnet
resource "aws_subnet" "public" {   
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
  
  # private subnet
  resource "aws_subnet" "private" {   
  count = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  
  tags = merge (
         local.common_tags ,
         { # roboshop-dev-private-us-east-1a
           Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
         },
         var.private_subnet_tags 
     )
   
  }
# database subnet
  resource "aws_subnet" "database" {   
  count = length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  
  tags = merge (
         local.common_tags ,
         { # roboshop-dev-database-us-east-1a
           Name = "${var.project}-${var.environment}-database-${local.az_names[count.index]}"
         },
         var.database_subnet_tags 
     )
   
  }

  # 4. route table creation 
  # public route table
  resource "aws_route_table" "public" {
        vpc_id = aws_vpc.main.id

        route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
        }

        tags = merge (
                local.common_tags ,
                { # roboshop-dev-public
                   Name = "${var.project}-${var.environment}-public"
                },
                var.public_route_table_tags 
            )
    }

    # private route table
  resource "aws_route_table" "private" {
        vpc_id = aws_vpc.main.id

        route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
        }

        tags = merge (
                local.common_tags ,
                { # roboshop-dev-private
                   Name = "${var.project}-${var.environment}-private"
                },
                var.private_route_table_tags 
            )
    }  

        # database route table
  resource "aws_route_table" "database" {
        vpc_id = aws_vpc.main.id

        route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
        }

        tags = merge (
                local.common_tags ,
                { # roboshop-dev-database
                   Name = "${var.project}-${var.environment}-database"
                },
                var.database_route_table_tags 
            )
    }  