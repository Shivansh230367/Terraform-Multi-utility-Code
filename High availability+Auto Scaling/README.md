# Task-3 Documentation
# High Availability AWS Architecture – Terraform Deployment

## Architecture Summary
### 1. VPC and Subnets
- Custom VPC: `10.20.0.0/16`
- Two public subnets (AZ-a, AZ-b)
- Two private subnets (AZ-a, AZ-b)
- Ensures multi‑AZ high availability

### 2. Routing
- Public subnets → IGW for internet access
- Private subnets → NAT Gateway for secure outbound traffic
- Separate route tables for public and private tiers

### 3. Load Balancer
- Application Load Balancer (ALB) deployed in public subnets
- Listener on port 80
- Target Group with health checks (`/`, 200–399)

### 4. Auto Scaling Group (ASG)
- Instances launched in private subnets only
- Controlled by Launch Template (Amazon Linux 2 + Nginx)
- Minimum 1, maximum 2 instances
- Automatically registers instances with ALB Target Group

### 5. Security
- ALB SG: Allows HTTP (80) from anywhere
- App SG: Allows HTTP only from ALB SG
- Instances have no public IPs (protected in private subnets)

## Traffic Flow
1. User requests the ALB DNS name.
2. ALB receives request in public subnet.
3. ALB forwards request to Target Group.
4. Target Group routes to EC2 instances in private subnets.
5. Nginx on EC2 returns HTML response.
6. Response flows back through ALB to the user.
![task_3-1](https://github.com/user-attachments/assets/b0a04d5f-4fb4-41bd-9a00-5e2de2e1016e)
![task_3-2](https://github.com/user-attachments/assets/f6d05cfb-a549-4184-832d-5792190be0e4)

![task_3-3](https://github.com/user-attachments/assets/3d0f0f9e-e9a3-4c91-8685-d40a22fb799e)

![task_3-4](https://github.com/user-attachments/assets/1e07f3ef-89bf-4d92-87e9-52f785a2404e)
![task_3-5](https://github.com/user-attachments/assets/2962c376-7929-4014-9fb3-c1a17026e55a)
![task_3-6](https://github.com/user-attachments/assets/4e62d2ee-5f9d-4c8e-9aee-929b32356cac)

