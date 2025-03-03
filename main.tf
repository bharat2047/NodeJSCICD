terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

resource "aws_security_group" "nodejs_sg" {
  name        = "sg-065c0e6e31852116a"
  description = "Security group for NodeJS server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodeJS application access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

resource "aws_instance" "nodejs_server" {
  ami                    = "ami-0df8c184d5f6ae949"  
  instance_type         = "t2.micro"
  subnet_id             = "subnet-07eec9e534360858e"  
  vpc_security_group_ids = [aws_security_group.nodejs_sg.id]
  associate_public_ip_address = true
  key_name              = "aws"

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  tags = {
    Name = var.instance_name
  }
}

resource "null_resource" "wait_for_ssh" {
  depends_on = [aws_instance.nodejs_server]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/var/jenkins_home/.ssh/aws.pem")
      host        = aws_instance.nodejs_server.public_ip
      timeout     = "240s"
    }

    inline = ["echo 'SSH is ready!'"]
  }
}

output "instance_id" {
  value = aws_instance.nodejs_server.id
}

output "public_ip" {
  value = aws_instance.nodejs_server.public_ip
}


        stage('Create EC2 Instance') {
            steps {
                script {
                    sh 'terraform init'
                    sh 'terraform plan -out=tfplan'
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
    }
}


