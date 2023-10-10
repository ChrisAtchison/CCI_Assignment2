resource "aws_launch_template" "main" {
  name_prefix   = "cci-"
  image_id      = "ami-0e812285fd54f7620"
  instance_type = "t2.micro"
  user_data     = file("./static_files/user_data.sh")
  key_name      = aws_key_pair.main.key_name
  network_interfaces {
    security_groups = [aws_security_group.main.id]
  }
}

resource "aws_autoscaling_group" "main" {
  name               = "cci"
  availability_zones = module.vpc.availability_zones
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  launch_template {
    id      = aws_launch_template.main.id
    version = aws_launch_template.main.latest_version
  }
}

resource "aws_key_pair" "main" {
  public_key = file("./.ssh/id_rsa.pub")
}

resource "aws_security_group" "main" {
  description = "LB Traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.lb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.public_subnets_cidr_blocks]
  }
}
