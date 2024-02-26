provider "aws" {
    region = "eu-west-1"
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-0ef9e689241f0bb6e"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash 
                echo "Hello, world" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF

    #Required when using a launch config with an ASG.
    lifecycle {
        create_before_destroy = true
    }      
}
resource "aws_security_group" "instance" {
    name = "terraform-example-instance"
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_lb_target_group" "asg" {
name = "terraform-asg-example"
port = "80"
protocol = "HTTP"
vpc_id = "vpc-094fe25dc3f898917"

health_check {
  path = "/"
  protocol = "HTTP"
  matcher = "200"
  interval = "15"
  timeout = "3"
  healthy_threshold = "2"
  unhealthy_threshold = "2"
}
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = ["subnet-09dc3dbfbf733fe26", "subnet-0c23b4d7b5ccf556a", "subnet-015cd0e15d3efa4b6"]

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
      key = "Name"
      value = "terra4m_sample"
      propagate_at_launch = true
    }
}

resource "aws_lb" "http" {
  load_balancer_type = "application"
  subnets = ["subnet-09dc3dbfbf733fe26", "subnet-0c23b4d7b5ccf556a", "subnet-015cd0e15d3efa4b6"]
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "sample_LB_listener" {
  load_balancer_arn = aws_lb.http.arn
  port = 80
  protocol = "HTTP"

  #By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
}
}

resource "aws_security_group" "alb" {
    name = "alb_sg"

    #Allow inbound traffic
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
  #Allow outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.sample_LB_listener.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

