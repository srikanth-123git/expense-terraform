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

resource "aws_launch_template" "main" {
  name = "eks-${var.env}"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 100
      encrypted             = true
      kms_key_id            = var.kms_key_id
      delete_on_termination = true
    }
  }

}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.env}-eks-ng"
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = var.subnet_ids
  capacity_type   = "SPOT"
  instance_types  = ["t3.large"]

  launch_template {
    name    = "eks-${var.env}"
    version = "$Latest"
  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}

