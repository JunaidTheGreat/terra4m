provider "aws" {
    region = "eu-west-1"
}

resource "aws_instance" "example" {
    ami = "ami-0ef9e689241f0bb6e"
    instance_type = "t2.micro"
    tags = {
        Name = "terraform_example"
        }
    }