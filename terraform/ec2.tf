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

resource "aws_lb" "main" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [for subnet in module.vpc.public_subnets : subnet.id]
}

resource "aws_target_group" "main" {
  name        = "main"
  target_type = "alb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_target_group.main.arn
  target_id        = aws_autoscaling_group.main.id
  port             = 80
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}

resource "aws_security_group" "lb" {
  name        = "lb"
  description = "Allow HTTP Traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc.public_subnets_cidr_blocks]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.public_subnets_cidr_blocks]
  }
}
