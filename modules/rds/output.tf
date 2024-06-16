//The host address, user name and database name of RDS DB is used by WordPress deployment module it is required to output them.

output "rds_db_user" {
  value = aws_db_instance.rds_db.username
}

//output "rds_db_name" {
//  value = aws_db_instance.rds_db.db_name
//}

output "rds_db_host" {
  value = aws_db_instance.rds_db.address
}