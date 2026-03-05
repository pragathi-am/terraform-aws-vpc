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

        tags = merge (
                local.common_tags ,
                { # roboshop-dev-database
                   Name = "${var.project}-${var.environment}-database"
                },
                var.database_route_table_tags 
            )
    }  

    #5.1  route table association public thru IGW (0.0.0.0/0) 

    resource "aws_route" "public" {
        route_table_id            = aws_route_table.public.id
        destination_cidr_block    = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
   }

   #6. create NAT. for that we need to create first Elastic IP ( static)

   resource "aws_eip" "nat" {
        domain         = "vpc"   
        tags = merge (
                local.common_tags ,
                { # roboshop-dev-nat
                   Name = "${var.project}-${var.environment}-nat"
                },
                var.eip_tags 
            )
    }

    # place the above created NAT in public subnet.      
    # here depends_on means , before cretion of nat_gatway, we have to define internet gateway. 
    resource "aws_nat_gateway" "main" {
        allocation_id = aws_eip.nat.id
        subnet_id = aws_subnet.public[0].id # here 0 means, we r creating only east-1a only
        tags = merge (
                local.common_tags ,
                { # roboshop-dev
                   Name = "${var.project}-${var.environment}"
                },
                var.nat_gateway_tags 
            )
        depends_on = [aws_internet_gateway.main]
    }

    # 5.2 route table association private/database thru NAT (0.0.0.0/0) 

    resource "aws_route" "private" {
        route_table_id            = aws_route_table.private.id
        destination_cidr_block    = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
   }

    resource "aws_route" "database" {
        route_table_id            = aws_route_table.database.id
        destination_cidr_block    = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
   }

   # route table subnet associations 

   resource "aws_route_table_association" "public" {
       count = length(var.public_subnet_cidrs)
       subnet_id = aws_subnet.public[count.index].id
       route_table_id = aws_route_table.public.id
     }

     resource "aws_route_table_association" "private" {
       count = length(var.private_subnet_cidrs)
       subnet_id = aws_subnet.private[count.index].id
       route_table_id = aws_route_table.private.id
     }

     resource "aws_route_table_association" "database" {
       count = length(var.database_subnet_cidrs)
       subnet_id = aws_subnet.database[count.index].id
       route_table_id = aws_route_table.database.id
     }