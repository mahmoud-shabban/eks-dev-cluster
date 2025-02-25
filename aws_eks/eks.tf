module "dev-eks-cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                             = var.cluster-name
  cluster_version                          = var.cluster-version
  cluster_endpoint_public_access           = true
#   putin_khuylo                             = false
  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group              = true
  enable_irsa                              = true
  # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = aws_vpc.eks_vpc.id
  subnet_ids = [for k, v in aws_subnet.subnets : v.id if strcontains(k, "private")] # private subnets

  eks_managed_node_groups = {
    managed-ng-1 = {
      instance_types = ["m6i.large"]

      min_size     = 2
      max_size     = 5
      desired_size = 2
    }
  }

  depends_on = [ aws_vpc.eks_vpc, aws_subnet.subnets, aws_internet_gateway.igw, aws_nat_gateway.nat-gw ]
}