variable "name" {
  description = "Name prefix for all networking resources, e.g. \"eks-scale-to-zero-dev\"."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name that will live in this VPC. Used only to apply the kubernetes.io subnet discovery tags ELB/ALB controllers require."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "azs" {
  description = "Availability zones to spread subnets across. Two is enough for a dev/staging portfolio cluster; EKS requires at least two for the control plane."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "At least two availability zones are required by EKS."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ, in the same order as var.azs."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (nodes + control plane ENIs live here), one per AZ, in the same order as var.azs."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all private subnets instead of one per AZ. Cuts NAT cost by up to N-1x at the cost of cross-AZ data transfer and single-AZ blast radius if that AZ has an outage. Recommended for a non-HA portfolio project."
  type        = bool
  default     = true
}

variable "enable_s3_gateway_endpoint" {
  description = "Create the S3 gateway VPC endpoint. This is free (no hourly or per-GB charge) and always worth enabling."
  type        = bool
  default     = true
}

variable "enable_interface_endpoints" {
  description = "Create ECR/STS interface endpoints (ecr.api, ecr.dkr, sts). Each interface endpoint costs ~$0.01/hr *per AZ* (~$7.30/mo/AZ) plus data processing. At this project's traffic volume, that's roughly $44/mo for 3 endpoints across 2 AZs -- almost certainly more than the NAT Gateway data-processing charges it would offset. Left off by default for cost; flip on if you want to demonstrate the pattern or if NAT data-processing costs start to dominate."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
