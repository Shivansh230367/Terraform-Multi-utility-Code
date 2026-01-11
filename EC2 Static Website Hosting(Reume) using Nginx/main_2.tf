terraform {
required_providers {
aws = { source = "hashicorp/aws" }
}
required_version = ">= 1.3.0"
}

provider "aws" {
region = var.region
}


variable "region" {
type = string
default = "us-east-1"
}

variable "name_prefix" {
type = string
default = "Shivansh-Chaurasia"
}

variable "allowed_ssh_cidr" {
type = string
default = ""
}

variable "ssh_public_key" {
type = string
default = ""
}

variable "resume_html" {
type = string
default = <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<title>Resume - Shivansh Chaurasia</title>
<style>
  body { font-family: Arial, sans-serif; padding: 30px; max-width: 900px; margin: auto; line-height: 1.6; }
  h1 { margin-bottom: 5px; font-size: 32px; }
  h2 { margin-top: 30px; border-bottom: 2px solid #333; padding-bottom: 5px; }
  h3 { margin-top: 10px; font-size: 18px; }
  .contact { color: #444; margin-bottom: 20px; }
  ul { margin-top: 5px; }
</style>
</head>

<body>

<h1>Shivansh Chaurasia</h1>
<div class="contact">
  Lucknow (226003) • 8081528660 • <a href="mailto:shivansh3023@gmail.com">shivansh3023@gmail.com</a><br>
  <a href="https://www.linkedin.com/in/shivansh-chaurasia-715014258">LinkedIn</a> • 
  <a href="https://github.com/Shivansh230367">GitHub</a>
</div>

<h2>Summary</h2>
<p>
Versatile and goal-oriented Computer Science Engineering student with strong foundations in 
software development and cloud technologies. Skilled in full-stack web development, database 
design, NLP/AI, and problem-solving. Quick to adapt, collaborative, and eager to contribute across 
Web Dev, Cloud, DevOps, and AI roles.
</p>

<h2>Education</h2>
<p>
<b>B.Tech in Computer Science Engineering</b> • Shri Ramswaroop Memorial College of Engineering and Management, Lucknow<br>
2022 – 2026
</p>

<h2>Professional Experience</h2>

<h3>AI Trainee — Edu Net Foundation (Remote) • Feb 2025 – Mar 2025</h3>
<ul>
  <li>Developed a sentiment analysis model achieving 85% accuracy.</li>
  <li>Collaborated on AI-powered feedback analysis tool improving insight accuracy by 25%.</li>
</ul>

<h3>Web Developer Intern — Cothon Solutions (Remote) • Dec 2024 – Jan 2025</h3>
<ul>
  <li>Participated in daily standups and demos, delivering 100% on-time project milestones.</li>
  <li>Contributed to 30+ monthly code reviews, reducing review time & improving quality.</li>
</ul>

<h3>Subject Matter Expert — Synergy Edu-Services (Remote) • May 2021 – Sep 2021</h3>
<ul>
  <li>Created 100+ educational modules for academic & industry needs.</li>
  <li>Maintained 98% accuracy under strict deadlines.</li>
</ul>

<h2>Projects</h2>
<ul>
  <li><b>Multi-Document Q&A Bot</b> — RAG-based document querying for 20 PDFs (1000 pages each).</li>
  <li><b>Multi-Lingual Document Translator</b> — OCR + translation to 100+ languages.</li>
  <li><b>News-It</b> — Full-stack app for personalized secure news from 150k+ sources.</li>
</ul>

<h2>Certifications</h2>
<ul>
  <li>AWS Cloud Practitioner Essentials</li>
  <li>OCI 2025 Certified DevOps Professional</li>
  <li>Introduction to Front-End Development</li>
</ul>

<h2>Skills</h2>
<b>Soft Skills:</b> Communication, Teamwork, Leadership, Adaptability<br>
<b>Hard Skills:</b> HTML, CSS, JavaScript, React.js, Python, Java<br>
<b>Tools:</b> VS Code, GitHub, AWS, Postman

</body>
</html>
EOF
}


resource "aws_vpc" "vpc" {
cidr_block = "10.0.0.0/16"
enable_dns_hostnames = true
tags = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_subnet" "public" {
vpc_id = aws_vpc.vpc.id
cidr_block = "10.0.1.0/24"
map_public_ip_on_launch = true
tags = { Name = "${var.name_prefix}-public-subnet" }
}

resource "aws_internet_gateway" "igw" {
vpc_id = aws_vpc.vpc.id
tags = { Name = "${var.name_prefix}-igw" }
}

resource "aws_route_table" "public_rt" {
vpc_id = aws_vpc.vpc.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}
tags = { Name = "${var.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
subnet_id = aws_subnet.public.id
route_table_id = aws_route_table.public_rt.id
}



resource "aws_security_group" "web_sg" {
name = "${var.name_prefix}-sg"
vpc_id = aws_vpc.vpc.id
description = "Allow HTTP and optional SSH"

ingress {
description = "HTTP"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

dynamic "ingress" {
for_each = var.allowed_ssh_cidr != "" ? [var.allowed_ssh_cidr] : []
content {
description = "SSH"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = [ingress.value]
}
}

egress {
description = "All outbound"
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

tags = { Name = "${var.name_prefix}-sg" }
}



resource "aws_key_pair" "kp" {
count = var.ssh_public_key == "" ? 0 : 1
key_name = "Shivansh_keypair"
public_key = var.ssh_public_key
}



data "aws_ami" "al2" {
most_recent = true
owners = ["amazon"]
filter {
name = "name"
values = ["amzn2-ami-hvm-*-x86_64-gp2"]
}
}



resource "aws_instance" "web" {
ami = data.aws_ami.al2.id
instance_type = "t2.micro"
subnet_id = aws_subnet.public.id
vpc_security_group_ids = [aws_security_group.web_sg.id]
associate_public_ip_address = true
key_name = length(aws_key_pair.kp) > 0 ? aws_key_pair.kp[0].key_name : null

root_block_device {
volume_size = 8
volume_type = "gp3"
encrypted = true
}

tags = { Name = "${var.name_prefix}-web" }

user_data = <<-EOF
#!/bin/bash
set -e
yum update -y
amazon-linux-extras enable nginx1
yum -y install nginx
cat > /usr/share/nginx/html/index.html <<'HTML'
${var.resume_html}
HTML
chown -R nginx:nginx /usr/share/nginx/html
chmod -R 750 /usr/share/nginx/html
#security headers
cat >> /etc/nginx/conf.d/security_headers.conf <<'NGX'
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options SAMEORIGIN;
server_tokens off;
NGX
systemctl enable --now nginx
EOF
}


output "public_ip" {
description = "Public IP of the web server (visit http://IP)"
value = aws_instance.web.public_ip
}

output "website_url" {
value = "http://${aws_instance.web.public_ip}"
}