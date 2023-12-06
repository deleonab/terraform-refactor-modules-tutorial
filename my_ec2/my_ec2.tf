resource "aws_instance" "my_instance" {
  count = var.ec2_count
  ami           = var.ami
  instance_type = var.instance_type
subnet_id = var.instance_subnet_id
  tags = {
    Name = "my_EC2-${count.index}"
  }
}
