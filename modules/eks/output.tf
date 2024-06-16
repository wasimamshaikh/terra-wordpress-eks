// We might need to refer this module for certain information required in other modules so we need to output those information and other modules can use variables and get these outputs assigned to them.

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet1_id" {
  value = aws_subnet.public_1.id
}

output "subnet2_id" {
  value = aws_subnet.public_2.id
}

output "igw_id" {
  value = aws_internet_gateway.internet_gw.id
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "node_groupname" {
  value = aws_eks_node_group.node_group.node_group_name
}

output "id_sg" {
  value = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}