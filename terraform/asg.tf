data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.sh")
  vars = {
    CONSUL_VERSION     = "1.8.1"
    NOMAD_VERSION      = "0.12.1"
    CONSUL_SERVER      = var.retry_join
    NODE_CLASS         = "${var.stack_name}-aws"
    TAILSCALE_AUTH_KEY = var.tailscale_auth_key
  }
}

resource "aws_launch_template" "nomad_client" {
  name_prefix            = "nomad-client"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.vpn-inbound.id, aws_security_group.vpn-outbound.id]
  user_data              = base64encode(data.template_file.user_data.rendered)
}

resource "aws_autoscaling_group" "nomad_client" {
  name               = "${var.stack_name}-clients"
  availability_zones = var.availability_zones
  desired_capacity   = 1
  min_size           = 0
  max_size           = 10

  launch_template {
    id      = aws_launch_template.nomad_client.id
    version = "$Latest"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}