variable "type" {
    default = "t2.micro"
}
// Environment name, used as prefix to name resources.
variable "environment" {
  default = "dev"
}


locals{
    environment = var.environment
    cidr_block_public = ["10.0.3.0/26","10.0.4.0/26"]
    cidr_block_vpc = "10.0.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]
    amilinux = "ami-0574da719dca65348"
    key_name                   = "jenkins"
    type                       = var.type
}

resource "aws_vpc" "vpc" {
  cidr_block           = local.cidr_block_vpc
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
/* Elastic IP */
resource "aws_eip" "eip" {
  vpc        = true
  tags = {
    Name        = "${local.environment}-EIP"
    Environment = "${local.environment}"
  }  
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.Jenkins.id
  allocation_id = aws_eip.eip.id
}

// /* NAT */
// resource "aws_nat_gateway" "nat" {
//   allocation_id = "${aws_eip.nat_eip.id}"
//   subnet_id     = aws_subnet.public_subnet[0].id
//   tags = {
//     Name        = "nat"
//     Environment = "${local.environment}"
//   }
// }

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

// resource "aws_route" "private_nat_gateway" {
//   route_table_id         = "${aws_route_table.route[1].id}"
//   destination_cidr_block = "0.0.0.0/0"
//   nat_gateway_id         = aws_nat_gateway.nat.id
//   depends_on = [aws_nat_gateway.nat]
// }

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
//   user_data       = "${file("install_jenkins.sh")}"
  provisioner "remote-exec" {
    inline = [
      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt update -qq",
      "sudo apt install -y default-jre",
      "sudo apt install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080",
      "sudo sh -c \"iptables-save > /etc/iptables.rules\"",
      "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections",
      "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections",
      "sudo apt-get -y install iptables-persistent",
      "sudo ufw allow 8080",
    ]
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("C:\\Users\\drsri\\OneDrive\\Desktop\\Suresh\\jenkins.pem")
  }
  tags = {
    Name        = "${local.environment}-jenkins"
    Environment = local.environment
  }
}