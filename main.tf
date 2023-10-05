provider "aws" {
  region     = "ap-south-1"
}

resource "tls_private_key" "prkey" {
  algorithm  = "RSA"
}

resource "aws_key_pair" "webkey1" {
  key_name   = "webkey1"
  public_key = tls_private_key.prkey.public_key_openssh
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
}

resource "aws_security_group" "allow_80" {
  name        = "allow_80"
  description = "Allow port 80"

  ingress {
    description = "incoming http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "incoming ssh"
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

  tags = {
    Name = "allow_80"
  }
}


resource "aws_instance" "webserver" {
  ami           = var.ami_id
  instance_type = "t3a.micro"
  availability_zone = aws_ebs_volume.web_volume.availability_zone
  key_name      = "webkey1"
  security_groups = ["${aws_security_group.allow_80.name}"]
 
  tags = {
    Name = "WebOS"
	map-migrated = "d-server-01w1643zlizp1x"
  }
}


resource "aws_ebs_volume" "web_volume" {
  availability_zone = "ap-south-1a"
  size              = 1
  
  tags = {
    Name = "web_volume"
  }
}



resource "null_resource" "imp_soft"  {
  depends_on = [aws_instance.webserver,
                aws_volume_attachment.ebs_att]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key =tls_private_key.prkey.private_key_pem
    host     = aws_instance.webserver.public_ip
  }

}



resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdr"
  volume_id   = aws_ebs_volume.web_volume.id
  instance_id = aws_instance.webserver.id
  force_detach = true
}


resource "null_resource" "wepip"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.webserver.public_ip} > publicip.txt"
  	}
}
