data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "${var.environment}-k8s-sg"
  description = "Strict security group for Kubernetes"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    description = "SSH from Admin IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip] 
  }

  ingress {
    description = "K8s API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  description = "K8s NodePorts"
  from_port   = 30000
  to_port     = 32767
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.environment}-sg" }
}

# --- MASTER ---
resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  source_dest_check      = false
  root_block_device { volume_size = 15 }
  tags = { Name = "k8s-master", Role = "master" }
}

# --- WORKERS ---
resource "aws_instance" "worker_data" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  source_dest_check      = false
  root_block_device { volume_size = 10 }
  tags = { Name = "k8s-worker-data" }
}

resource "aws_instance" "worker_backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  source_dest_check      = false
  root_block_device { volume_size = 10 }
  tags = { Name = "k8s-worker-backend" }
}

resource "aws_instance" "worker_frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  source_dest_check      = false
  tags = { Name = "k8s-worker-frontend" }
}

resource "aws_instance" "worker_ml" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  source_dest_check      = false
  tags = { Name = "k8s-worker-ml" }
}

resource "aws_instance" "worker_runner" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  source_dest_check      = false
  tags = { Name = "k8s-worker-runner" }
}