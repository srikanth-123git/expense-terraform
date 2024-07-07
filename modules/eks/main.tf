resource "aws_eks_cluster" "cluster" {
  name     = "${var.env}-eks"
  role_arn = aws_iam_role.cluster-role.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_id
    }
    resources = ["secrets"]
  }

}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.env}-eks-ng"
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = var.subnet_ids
  capacity_type   = "SPOT"
  instance_types  = ["t3.large"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}

