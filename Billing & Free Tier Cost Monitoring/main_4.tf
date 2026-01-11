terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "resource_prefix" {
  type    = string
  default = "Shivansh-Chaurasia"
}

variable "alert_email" {
  type    = string
  default = "shivansh3023@gmail.com"
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_sns_topic" "billing_topic" {
  name = "${var.resource_prefix}-billing-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.billing_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# billing alarm
resource "aws_cloudwatch_metric_alarm" "billing_alarm_inr_100" {
  provider            = aws.us_east_1
  alarm_name          = "${var.resource_prefix}_billing_inr_100"
  alarm_description   = "Alarm when estimated charges exceed 100 INR"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  statistic           = "Maximum"
  period              = 21600
  threshold           = 100

  dimensions = {
    Currency = "INR"
  }

  alarm_actions      = [aws_sns_topic.billing_topic.arn]
  treat_missing_data = "notBreaching"
}


resource "aws_budgets_budget" "free_tier_usage_ec2" {
  name         = "${var.resource_prefix}_free_tier_usage_ec2"
  budget_type  = "USAGE"
  limit_unit   = "Percent"
  limit_amount = "100"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}


resource "aws_budgets_budget" "free_tier_usage_s3" {
  name         = "${var.resource_prefix}_free_tier_usage_s3"
  budget_type  = "USAGE"
  limit_unit   = "Percent"
  limit_amount = "100"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}



resource "aws_budgets_budget" "free_tier_usage_lambda" {
  name         = "${var.resource_prefix}_lambda_free_tier_usage"
  budget_type  = "USAGE"

  limit_amount = "1000000"   
  limit_unit   = "GB-Seconds"

  time_unit = "MONTHLY"
}


output "billing_alarm_name" {
  value = aws_cloudwatch_metric_alarm.billing_alarm_inr_100.alarm_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.billing_topic.arn
}

output "free_tier_budget_names" {
  value = [
    aws_budgets_budget.free_tier_usage_ec2.name,
    aws_budgets_budget.free_tier_usage_s3.name,
    aws_budgets_budget.free_tier_usage_lambda.name
  ]
}
