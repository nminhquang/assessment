module "eks_managed_node" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.0"

  cluster_name    = local.name_prefix
  cluster_version = var.eks_version

  # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.application_subnet_ids
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.this.arn
    resources        = ["secrets"]
  }
  eks_managed_node_groups = {
    small = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2_x86_64"
      instance_types = ["m6i.large"]

      min_size = 2
      max_size = 5
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2
    }
  }

  tags = local.tags
}