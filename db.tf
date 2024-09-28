resource "aws_db_instance" "mysql" {
  # Use mysql free tier template
  allocated_storage     = 20
  max_allocated_storage = 0
  db_name               = "wanted"
  engine                = "mysql"
  engine_version        = "8.0.35"
  instance_class        = "db.t4g.micro"
  storage_type          = "gp3"
  username              = var.db_user
  password              = var.db_pass
  parameter_group_name  = "default.mysql8.0"
  skip_final_snapshot   = true
  network_type          = "IPV4"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_sbntg.name
  auto_minor_version_upgrade = false
  publicly_accessible   = false
  apply_immediately = true
}