resource "aws_instance" "ec2_instance_public" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet[0].id
  depends_on      = [aws_security_group.public_sg]
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name               = aws_key_pair.ubuntu_key_pair.key_name

  user_data = file("${path.module}/data/install.sh")
provisioner "file" {
    source      = var.local_file_path
    destination = var.remote_file_path
connection {
    type        = "ssh"
    host        = self.public_ip
    user        = var.user
    private_key = file("${aws_key_pair.ubuntu_key_pair.key_name}.pem")
    timeout     = "4m"
  }
}

provisioner "remote-exec" {
    inline = [ "chmod 600 ${var.remote_file_path}" ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = var.user
      private_key = file("${aws_key_pair.ubuntu_key_pair.key_name}.pem")
      timeout     = "4m"  
}
}
  tags = {
    Name = var.private_ec2_name
  }
}


resource "aws_instance" "ec2_instance_private" {
  count           = length(var.ec2_instance_names)
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.ubuntu_key_pair.key_name
  subnet_id       = aws_subnet.private_subnet[count.index].id
  depends_on      = [aws_security_group.private_sg, aws_route_table.private, aws_route_table_association.private]
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  user_data = file("${path.module}/data/install.sh")

  tags = {
    Name = var.ec2_instance_names[count.index]
  }
}


data "aws_instances" "frontend_instances" {
    depends_on = [ aws_instance.ec2_instance_private ]
  filter {
    name   = "tag:Name"
    values = ["frontend"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instances" "backend_instances" {
    depends_on = [ aws_instance.ec2_instance_private ]
  filter {
    name   = "tag:Name"
    values = ["backend"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}