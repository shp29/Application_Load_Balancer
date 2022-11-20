# Create vpc :
resource "aws_vpc" "myvpc" {
  cidr_block = var.my_vpc.cidr
  tags = {
    Name = var.my_vpc.vpc_name
  }
}

# Creating Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "my-test-igw"
  }
}

# Public Route Table

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "my-test-public-route"
  }
}

# Create dedicated Subnet1 for your vpc :
resource "aws_subnet" "mysubnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = element(var.my_vpc.subnet_cidr,0)
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"
  tags = {
    Name = element(var.my_vpc.subnet_name,0)
  }
}

# Associate Public Subnet1 with Public Route Table
resource "aws_route_table_association" "public_subnet_assoc1" {
  route_table_id = "${aws_route_table.public_route.id}"
  subnet_id      = "${aws_subnet.mysubnet1.id}"
  depends_on     = ["aws_route_table.public_route", "aws_subnet.mysubnet1"]
}

# Create dedicated Subnet2 for your vpc :
resource "aws_subnet" "mysubnet2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = element(var.my_vpc.subnet_cidr,1)
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1b"
  tags = {
    Name = element(var.my_vpc.subnet_name,1)
  }
}
# Associate Public Subnet2 with Public Route Table
resource "aws_route_table_association" "public_subnet_assoc2" {
  route_table_id = "${aws_route_table.public_route.id}"
  subnet_id      = "${aws_subnet.mysubnet1.id}"
  depends_on     = ["aws_route_table.public_route", "aws_subnet.mysubnet2"]
}

# Create instance1 : (attached on the top of the subnet1)
resource "aws_instance" "myec2-1" {
  ami = var.ami
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet1.id
  tags = {
    Name = "ec2_instance1"
  }
}

# Create instance2 : (attached on the top of the subnet1)
resource "aws_instance" "myec2-2" {
  ami = var.ami
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet2.id
  tags = {
    Name = "ec2_instance2"
  }
}

# Security Group Creation
resource "aws_security_group" "my-alb-sg" {
  name   = "my-alb-sg"
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_security_group_rule" "inbound_ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_http" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_all" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.my-alb-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
#create aws_lb target groups
resource "aws_lb_target_group" "my-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "my-test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.myvpc.id
}

#attach instances with target group
resource "aws_lb_target_group_attachment" "my-alb-target-group-attachment1" {
  target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
  target_id        = aws_instance.myec2-1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "my-alb-target-group-attachment2" {
  target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
  target_id        = aws_instance.myec2-1.id
  port             = 80
}

# Create alb resource

resource "aws_lb" "my-aws-alb" {
  name     = "my-test-alb"
  internal = false

  security_groups = [
    "${aws_security_group.my-alb-sg.id}",
  ]

  subnets = [
    aws_subnet.mysubnet1.id,
    aws_subnet.mysubnet2.id
  ]

  tags = {
    Name = "my-test-alb"
  }
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}


#add aws listener

resource "aws_lb_listener" "my-test-alb-listner" {
  load_balancer_arn = "${aws_lb.my-aws-alb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
  }
}
