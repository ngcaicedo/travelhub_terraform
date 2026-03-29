output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}

output "target_group_arns" {
  value = { for name, tg in aws_lb_target_group.this : name => tg.arn }
}

output "target_group_names" {
  value = { for name, tg in aws_lb_target_group.this : name => tg.name }
}
