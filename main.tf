terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}

resource "aws_lb_target_group" "target_group" {
  name     = "targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-03c2c97fa33624914"
  health_check {
    interval = 10
  }
}

resource "aws_lb" "load_balancer" {
  name               = "loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0f72fb49b5d8ffe51"]
  subnets            = ["subnet-024f0492d8241dfcb", "subnet-071e85a626ca32e82", "subnet-02f8fb042559ad80f"]

}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

}



resource "aws_autoscaling_group" "bar" {
  name                 = "terraform-asg-example"
  launch_configuration = aws_launch_configuration.as_conf.name
  target_group_arns    = [aws_lb_target_group.target_group.arn]
  min_size             = 1
  max_size             = 4
  desired_capacity     = 2
  availability_zones   = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}
data "template_file" "init" {
  template = file("init.tpl")
  vars = {
    lb_dns = "${aws_lb.load_balancer.dns_name}"
  }
}
resource "aws_launch_configuration" "as_conf" {
  name_prefix     = "instance-terraform"
  image_id        = "ami-0c6ebbd55ab05f070"
  instance_type   = "t2.micro"
  key_name        = "wordpressMA"
  security_groups = ["sg-0f72fb49b5d8ffe51"]
  user_data       = data.template_file.init.rendered
  lifecycle {
    create_before_destroy = true
  }
}

