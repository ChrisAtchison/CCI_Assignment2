resource "aws_instance" "a" {
  ami                    = "ami-0e812285fd54f7620 "
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.lb.id]
  subnet_id              = module.vpc.public_subnets[0]
  availability_zone      = module.vpc.availability_zones[0]
}

resource "aws_instance" "b" {
  ami                    = "ami-0e812285fd54f7620 "
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.lb.id]
  subnet_id              = module.vpc.public_subnets[1]
  availability_zone      = module.vpc.availability_zones[1]
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
  for_each = {
    for k, v in aws_instance.* :
    v.id => v
  }

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = each.value.id
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
