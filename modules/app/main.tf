resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}


resource "aws_instance" "instance" {
  ami                    = data.aws_ami.ami.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id             = var.subnets[0]

  tags = {
    Name    = var.component
    monitor = "yes"
    env     = var.env
  }
}

# resource "null_resource" "ansible" {
#   provisioner "remote-exec" {
#
#     connection {
#       type     = "ssh"
#       user     = jsondecode(data.vault_generic_secret.ssh.data_json).ansible_user
#       password = jsondecode(data.vault_generic_secret.ssh.data_json).ansible_password
#       host     = aws_instance.instance.public_ip
#     }
#
#     inline = [
#       "sudo pip3.11 install ansible hvac",
#       "ansible-pull -i localhost, -U https://github.com/Srikanth-Git123/expense-ansible get-secrets.yml -e env=${var.env} -e role_name=${var.component} -e vault_token=${var.vault_token}",
#       "ansible-pull -i localhost, -U https://github.com/Srikanth-Git123/expense-ansible expense.yml -e env=${var.env} -e role_name=${var.component} -e @secrets.json -e @app.json",
#       "rm -f ~/secrets.json ~/app.json"
#     ]
#   }
# }

resource "aws_route53_record" "record" {
  name           = "${var.component}-${var.env}"
  type           = "A"
  zone_id        = var.zone_id
  records        = [aws_instance.instance.private_ip]
  ttl            = 30
}
#