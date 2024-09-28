output "web_url" {
  value = "https://${aws_lb.web_lb.dns_name}/"
}

output "mysql_connection" {
  value = "mysql://${var.db_user}@${aws_db_instance.mysql.endpoint}/${aws_db_instance.mysql.db_name}"
}