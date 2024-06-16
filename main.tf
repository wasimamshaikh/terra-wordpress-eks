//Use module "eks_module" to setup EKS Cluster and node group.

module "eks_module" {
  source      = "./modules/eks"
  VPC_CIDR    = var.VPC_CIDR
  PUBSUB1CIDR = var.PUBSUB1CIDR
  PUBSUB2CIDR = var.PUBSUB2CIDR
  ZONE1       = var.ZONE1
  ZONE2       = var.ZONE2
}

//Use rds_module and pass the required variables using outputs of eks module for creation of RDS database.

module "rds_module" {
  source = "./modules/rds"
  subnets = [module.eks_module.subnet1_id, module.eks_module.subnet2_id]
  vpc_id = module.eks_module.vpc_id
  sg_id = module.eks_module.id_sg
  db_password = var.ENTER_DB_PASS
}

module "wordpress_dep" {
  source = "./modules/wp_deployment"
  cluster_name = module.eks_module.node_groupname
  node_group = module.eks_module.node_groupname
  wp_db_host = module.rds_module.rds_db_host
  wp_db_user = module.rds_module.rds_db_user
  wp_db_pass = var.ENTER_DB_PASS
}

// Get the output host name of wordpress loadbalencer and open the URL using chrome browser.

output "wp_hostname" {
  value = module.wordpress_dep.wordpress_hostname
}

resource "null_resource" "open_in_chrome" {
  depends_on = [module.wordpress_dep]
  provisioner "local-exec" {
    command = "start chrome ${module.wordpress_dep.wordpress_hostname}"
  }
}