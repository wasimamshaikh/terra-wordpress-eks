// Create a DB subnet group that is used by RDS while creating a DB server.

resource "aws_db_subnet_group" "db_subnet" {
  name       = "rds_subnets"
  subnet_ids = var.subnets
  tags = {
    Name = "My DB subnet group"
  }
}

// Create a security group that is nothing but a firewall for RDS DB which decides who can connect to the database server. Add allow ingress rule with port 3306 for MySQL to only clients that comes with the security group that is associated by EKS.

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow mysql"
  vpc_id      = var.vpc_id

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_tls"
  }
}

resource "aws_security_group_rule" "inbound" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds_sg.id
  source_security_group_id = var.sg_id
  to_port           = 3306
  type              = "ingress"
}

// Create RDS database with MySQL Engine with desired specifications and provide the DB subnet group and security group, password for DB is entered using variable at run time.

resource "aws_db_instance" "rds_db" {
  depends_on = [ var.subnets, var.vpc_id, var.sg_id]
  allocated_storage    = 20
  identifier = "database-wp"
  db_subnet_group_name = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  port = "3306"
  storage_type = "gp2"
  publicly_accessible = false
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
//  name                 = "mysql_wp_db"
  username             = "admin"
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}