provider "aws" {
  region = var.region
}

# 1) VPC + subnet + IGW + route table
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "trend-vpc" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "trend-igw" }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags = { Name = "trend-public-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.gw.id }
  tags = { Name = "trend-public-rt" }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 2) Security group for Jenkins (allow 22, 8080, 3000)
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress { from_port=0; to_port=0; protocol="-1"; cidr_blocks=["0.0.0.0/0"] }
}

# 3) IAM role for EC2 to allow EKS/Docker/push (optional more rights)
resource "aws_iam_role" "ec2_role" {
  name = "trend-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ec2_assume" {
  statement { actions = ["sts:AssumeRole"] principals { type="Service" identifiers=["ec2.amazonaws.com"] } }
}

resource "aws_iam_role_policy_attachment" "attach_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# attach AmazonEC2ContainerRegistryFullAccess if you push images to ECR; etc.

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "trend-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# 4) EC2 instance for Jenkins
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter { name="name" values=["amzn2-ami-hvm-*-x86_64-gp2"] }
}

resource "aws_instance" "jenkins" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id
  key_name      = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = file("jenkins_user_data.sh")

  tags = { Name = "jenkins-server" }
}

output "jenkins_public_ip" { value = aws_instance.jenkins.public_ip }
