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
/*
resource "aws_security_group" "ec2_SecurityGroup" {
  name        = "ec2Sg"
  description = "Allow EC2 inbound traffic"
  vpc_id      = "vpc-03c2c97fa33624914"

  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Efs_SecurityGroup" {
  name        = "EfSg"
  description = "Allow EFS NFS inbound traffic"
  vpc_id      = "vpc-03c2c97fa33624914"

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_SecurityGroup.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_db_instance" "default" {
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "8.0.28"
  instance_class      = "db.t3.micro"
  name                = "wordpress"
  username            = "wordpress"
  password            = "wordpress"
  identifier          = "wordpress"
  skip_final_snapshot = true
}
*/
resource "aws_efs_file_system" "foo" {
  creation_token = "efs_williboy"
  encrypted      = true

}
resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_efs_file_system.foo.id
  subnet_id      = "subnet-024f0492d8241dfcb"
  //security_groups = [aws_security_group.Efs_SecurityGroup.id]
  security_groups = ["sg-0f72fb49b5d8ffe51"]

}
resource "aws_efs_mount_target" "beta" {
  file_system_id = aws_efs_file_system.foo.id
  subnet_id      = "subnet-071e85a626ca32e82"
  //security_groups = [aws_security_group.Efs_SecurityGroup.id]
  security_groups = ["sg-0f72fb49b5d8ffe51"]

}
resource "aws_efs_mount_target" "charlie" {
  file_system_id = aws_efs_file_system.foo.id
  subnet_id      = "subnet-02f8fb042559ad80f"
  // security_groups = [aws_security_group.Efs_SecurityGroup.id]
  security_groups = ["sg-0f72fb49b5d8ffe51"]

}

resource "aws_lb_target_group" "target_group" {
  name     = "targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-03c2c97fa33624914"
  health_check {
    interval = 10
    matcher  = "200-302"
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
  desired_capacity     = 3
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
    efs_id = "${aws_efs_file_system.foo.dns_name}"
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
output "elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = aws_lb.load_balancer.dns_name
}


