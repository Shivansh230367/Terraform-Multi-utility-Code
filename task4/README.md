# Task- 4 Documentation

## 1. Why Cost Monitoring Is Important for Beginners

Cost monitoring is crucial for beginners because AWS follows a pay-as-you-go pricing model, and even small mistakes can create unexpected charges. New users exploring AWS often deploy services without knowing whether they fall within the Free Tier. Real-time alerts and monthly budgets help track spending and prevent bill shocks. Monitoring also builds good cloud habits and teaches users how different AWS services generate costs.

## 2.What Causes Sudden Increases in AWS Bills?

Sudden billing spikes commonly happen when EC2 instances, EBS volumes, or NAT Gateways are accidentally left running. High data transfer, excess S3 requests, or CloudWatch logs can also increase costs rapidly. Usage outside the Free Tier, auto-scaling events, or incorrect region deployments further lead to higher charges. Misconfigurations, third-party AMIs, and unexpected API calls can also trigger unexpected costs, making monitoring essential.

## This Terraform configuration deploys:

* Set a CloudWatch Billing Alarm at ₹100
* Enable Free Tier usage alerts
