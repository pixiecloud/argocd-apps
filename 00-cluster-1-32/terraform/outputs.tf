output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "cluster_name" {
  description = "Cluster name of the EKS cluster"
  value       = module.eks.cluster_name
}
output "vpc_id" {
  description = "VPC ID that the EKS cluster is using"
  value       = module.vpc.vpc_id
}

output "node_instance_role_name" {
  description = "IAM Role name that each Karpenter node will use"
  value       = module.eks_blueprints_addons.karpenter.node_iam_role_name
}

# ######## efs


# output "arn" {
#   value       = aws_efs_file_system.this.arn
#   description = "EFS ARN"
# }

# output "id" {
#   value       = aws_efs_file_system.this.id
#   description = "EFS ID"
# }

# output "dns_name" {
#   value       = aws_efs_file_system.this.dns_name
#   description = "EFS DNS name"
# }

# output "security_group_id" {
#   value       = aws_security_group.this.id
#   description = "EFS Security Group ID"
# }

# output "security_group_arn" {
#   value       = aws_security_group.this.arn
#   description = "EFS Security Group ARN"
# }

# output "security_group_name" {
#   value       = aws_security_group.this.name
#   description = "EFS Security Group name"
# }

# output "mount_target_ids" {
#   value       = coalescelist(aws_efs_mount_target.this.*.id, [""])
#   description = "List of EFS mount target IDs (one per Availability Zone)"
# }