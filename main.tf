variable "type" {
    default = "t2.micro"
}
// Environment name, used as prefix to name resources.
variable "environment" {
  default = "tomcat"
}


locals{
    environment = var.environment
    cidr_block_public = ["10.0.3.0/26","10.0.4.0/26"]
    availability_zones = ["us-east-1a", "us-east-1b"]
    amilinux = "ami-0574da719dca65348"
    key_name                   = "jenkins"
    type                       = var.type
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${local.environment}-vpc"
    Environment = local.environment
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.cidr_block_public[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name        = "${local.environment}-public-subnet"
    Environment = local.environment
  }
}

/*==== Subnets ======*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "${local.environment}-igw"
    Environment = "${local.environment}"
  }
}

/* Routing table for subnet */
resource "aws_route_table" "route" {
  // count = length(local.routetype)
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "${local.environment}-route-table"
    Environment = "${local.environment}"
  }
}

resource "aws_route" "route_pub" {
  route_table_id         = aws_route_table.route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnet.*.id)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.route.id
}

/* Security Group for the instance */
resource "aws_security_group" "jenkins" {
  name = "jenkins"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom tcp"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "output"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* AWS instance */
resource "aws_instance" "Jenkins" {
  ami = local.amilinux
  instance_type = local.type
  subnet_id = aws_subnet.public_subnet[0].id
  key_name = local.key_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  tags = {
    Name        = "${local.environment}-jenkins"
    Environment = local.environment
  }
}