output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}
