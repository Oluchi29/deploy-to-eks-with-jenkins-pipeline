#data "aws_ami" "latest-amazon-linux-image" {
#most_recent = true
#owners      = ["amazon"]
#filter {
# name   = "name"
#values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#}
#filter {
#name   = "virtualization-type"
#values = ["hvm"]
#}
#}

resource "aws_instance" "jenkinsapp-server" {
  #ami                         = data.aws_ami.latest-amazon-linux-image.id
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = "oluchi"
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_default_security_group.default-sg.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  user_data                   = file("new-jenkins-script.sh")
  tags = {
    Name = "${var.env_prefix}-jenkins-server"
  }
}