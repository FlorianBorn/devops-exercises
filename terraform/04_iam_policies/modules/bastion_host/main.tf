# variable "ssh_public_key" {
#   # List each field in `azurerm_route_table` that your module will access
#   type = object({
#     name = string
#     location = string
#     resource_group_name = string
#   })
# } 

resource "aws_security_group" "bastion_sg" {
  vpc_id = var.baho_vpc_id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow incoming SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    self        = false
  }

  egress {
    cidr_blocks = [var.baho_vpc_cidr_block]
    description = "allow outgoing, internal SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    self        = false
  }

  tags = {
    "Name" = "bastion_sg"
  }
}


resource "aws_instance" "bastion" {
  ami                         = var.baho_ami
  associate_public_ip_address = true
  #cpu_core_count = 2
  instance_type = var.baho_instance_type
  subnet_id     = var.baho_subnet_id
  # https://stackoverflow.com/questions/50740412/terraform-can-a-resource-be-passed-as-a-variable-into-a-module
  key_name               = var.baho_ssh_key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  user_data = <<-HERE
  #!/bin/bash
  sudo sed -i 's/\(.*\)AllowAgentForwarding\(.*\)/AllowAgentForwarding yes/' /etc/ssh/sshd_config
  sudo systemctl restart sshd.service
  sudo echo "hellow" > ~/user_data.log
  HERE

  tags = {
    "Name" = "bastion"
  }
}