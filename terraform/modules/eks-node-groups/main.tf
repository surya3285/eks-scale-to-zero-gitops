data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # node shell access via SSM Session Manager, no SSH keypair needed
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_eks_node_group" "system" {
  cluster_name    = var.cluster_name
  node_group_name = "system"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.system_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.system_desired_size
    min_size     = var.system_min_size
    max_size     = var.system_max_size
  }

  labels = {
    role = "system"
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.node]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

resource "aws_eks_node_group" "workload" {
  cluster_name    = var.cluster_name
  node_group_name = "workload"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.workload_instance_types
  capacity_type   = var.workload_capacity_type

  scaling_config {
    desired_size = var.workload_desired_size
    min_size     = var.workload_min_size
    max_size     = var.workload_max_size
  }

  labels = {
    role = "workload"
  }

  # Keeps system/ArgoCD pods from ever landing on the tier that disappears
  # nightly; demo app workloads must set a matching toleration.
  taint {
    key    = "dedicated"
    value  = "workload"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.tags, {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = "true"
  })

  depends_on = [aws_iam_role_policy_attachment.node]

  lifecycle {
    # The scaling-scheduler Lambda and Cluster Autoscaler both mutate desired
    # size at runtime; Terraform should stop caring about drift here after
    # initial creation so scheduled runs don't get clobbered by the next
    # terraform apply.
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Minimal policy for Cluster Autoscaler, scoped to only the ASGs this module
# tags for discovery. Attach via the irsa module from the environment root:
# the OIDC provider isn't known inside this module.
data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "Describe"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "eks:DescribeNodegroup",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Mutate"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "${var.cluster_name}-cluster-autoscaler"
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
  tags   = var.tags
}
