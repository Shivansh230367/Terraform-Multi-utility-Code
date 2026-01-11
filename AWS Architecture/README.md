
<img width="901" height="891" alt="AWS_architecture_shivansh drawio" src="https://github.com/user-attachments/assets/ce783ff8-5193-4759-aa76-68e40d7c0fca" />

# Task-5 Documentation

## Architecture Explanation

This architecture supports a scalable web application by distributing traffic through an Application Load Balancer (ALB). AWS WAF (Web Application Firewall) protects the ALB by filtering out malicious requests. The ALB sends traffic to an Auto Scaling Group (ASG) of EC2 instances located in public subnets. It automatically scales based on demand. The application’s data layer is in private subnets, where an Amazon RDS/Aurora database provides high availability and managed relational storage. To lessen the load on the database and speed up response times, ElastiCache Redis offers low-latency caching. Security Groups and NACLs ensure network protection at the instance and subnet levels. Amazon CloudWatch monitors application health, performance, and logs. S3 is used for storing application assets or logs. This design allows for scalability, security, and high performance for up to 10,000 concurrent users.
