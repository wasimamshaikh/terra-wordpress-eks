//Create a VPC named eks_vpc, and 2 public subnets with the tags as shown below while creation of EKS, EKS Cluster to use it.

resource "aws_vpc" "main" {
  cidr_block = var.VPC_CIDR
  instance_tenancy = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    "kubernetes.io/cluster/myeks-cluster" = "shared"
    Name = "eks_vpc"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.PUBSUB1CIDR
  map_public_ip_on_launch = "true"
  availability_zone       = var.ZONE1

  tags = {
    "kubernetes.io/cluster/myeks-cluster" = "shared"
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.PUBSUB2CIDR
  map_public_ip_on_launch = "true"
  availability_zone       = var.ZONE2

  tags = {
    "kubernetes.io/cluster/myeks-cluster" = "shared"
    "kubernetes.io/role/elb" = 1
  }
}

// Creating Internet Gateway for public subnets, one route table and associate it with both the subnets.

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "int-gw"
  }
}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "intgw_rt"
  }
}

resource "aws_route_table_association" "rt_a1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "rt_a2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.rt_public.id
}

//Create IAM role for creating EKS Cluster and attach the required policies i.e AmazonEKSClusterPolicy and AmazonEKSServicePolicy.

resource "aws_iam_role" "cluster_role" {
  name = "cluster_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster_role.name
}

// Create a EKS cluster named myeks-cluster and make this resource to depend on the IAM role policies attachment and subnets resources.

resource "aws_eks_cluster" "eks_cluster" {
  name     = "myeks-cluster"
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    endpoint_private_access = "true"
    subnet_ids = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  }

  tags = {
    Name = "myeks-cluster"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_subnet.public_2,
    aws_subnet.public_1
  ]
}

// Similar to EKS Cluster create IAM role for EKS Node group and attach the required policies.

resource "aws_iam_role" "node_role" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

// Create a private key pair for ssh connection to the instances running in node group when ever required.

resource "tls_private_key" "key1" {
  algorithm = "RSA"
}

resource "local_file" "keyfile" {
  depends_on = [tls_private_key.key1]
  content = tls_private_key.key1.private_key_pem
  filename = "webkey.pem"
}

resource "aws_key_pair" "webkey" {
  depends_on = [local_file.keyfile]
  key_name = "webkey"
  public_key = tls_private_key.key1.public_key_openssh
}

// Now create a EKS node group having maximum and desired 2 nodes , minimum 1 node. Give one label and the tags shown below is required so that the node group joins the EKS cluster created previously.

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "wp_ng"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  remote_access {
    ec2_ssh_key = "webkey"
  }
  instance_types = ["t2.micro"]
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  labels = {
    sub = "public"
  }
  tags = {
    "kubernetes.io/cluster/myeks-cluster" = "owned"
    "role" = "eks nodes"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_key_pair.webkey,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

// Updating Kubectl config file running AWS CLI command on local system as shown below using local execution of Terraform.

resource "null_resource" "local_exe1" {
  depends_on = [aws_eks_node_group.node_group]
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.eks_cluster.name}"
  }
}