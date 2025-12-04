// question2/main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
 type = string 
default = "us-east-1" 
}    // <span style="color:orange">OPTIONAL_REGION</span>
variable "resource_prefix" {
 type = string
 default = "Shivansh_Chaurasia"
} // <span style="color:red">REPLACE_ME_PREFIX</span>
variable "key_name" { 
type = string
 default = "Shivansh_keypair" 
 }       // <span style="color:red">REPLACE_ME_KEY_NAME</span>
variable "my_ip" {
 type = string
 default = "110.226.32.208/32" 
 }       // <span style="color:red">REPLACE_ME_YOUR_IP/32</span>

data "aws_ami" "amazon_linux" {
  owners      = ["137112412989"]
  most_recent = true
  filter { 
  name = "name"
  values = ["amzn2-ami-hvm-*-x86_64-gp2"] 
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.10.0.0/16"
  tags = { Name = "${var.resource_prefix}_vpc_q2" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = { Name = "${var.resource_prefix}_public_q2" }
}

data "aws_availability_zones" "available" {}

# Security Group
resource "aws_security_group" "web_sg" {
  name   = "${var.resource_prefix}_web_sg_q2"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from user IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["110.226.32.208/32"] # <span style="color:red">REPLACE_ME_YOUR_IP/32</span>
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"  # Free Tier eligible
  key_name                    = "Shivansh_keypair"  # <span style="color:red">REPLACE_ME_KEY_NAME</span>
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y nginx1
              systemctl enable nginx
              cat > /usr/share/nginx/html/index.html <<'HTML'
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

              HTML
              systemctl start nginx
              # Basic hardening
              adduser deployuser || true
              usermod -aG wheel deployuser || true
              sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
              systemctl restart sshd || true
              EOF

  tags = { Name = "${var.resource_prefix}_ec2_q2" }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
