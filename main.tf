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

resource "aws_autoscaling_group" "asgtest" {
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = ["subnet-09dc3dbfbf733fe26", "subnet-0c23b4d7b5ccf556a", "subnet-015cd0e15d3efa4b6"]

    min_size = 2
    max_size = 10

    tag {
      key = "Name"
      value = "terra4m_sample"
      propagate_at_launch = true
    }
}

resource "aws_lb" "sample_LB" {
  load_balancer_type = "application"
  subnets = ["subnet-09dc3dbfbf733fe26", "subnet-0c23b4d7b5ccf556a", "subnet-015cd0e15d3efa4b6"]
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "sample_LB_listener" {
  load_balancer_arn = aws_lb.sample_LB.arn
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