output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
