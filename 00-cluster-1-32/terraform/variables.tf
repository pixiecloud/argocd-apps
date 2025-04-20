## NOTE: It's going to use your AWS_REGION or AWS_DEFAULT_REGION environment variable,
## but you can define which on to use in terraform.tfvars file as well, or pass it as an argument
## in the CLI like this "terraform apply -var 'region=eu-west-1'"
variable "region" {
  description = "Region to deploy the resources"
  type        = string
}

# # ################################################################################
# # # AWS EFS CSI Driver
# # ################################################################################
variable "vpc_id" {
  description = "The VPC ID to associate with the EFS"
  type        = list(string)
  default     = [
    "vpc-05fe76c22b3059d48"
  ]
}

# Ensure you define subnet_ids variable in your variables.tf
variable "subnet_ids" {
  description = "List of subnet IDs where the EFS mount targets will be created"
  type        = list(string)
  default     = [
    "subnet-05330494f54f0da1c", # Subnet 1
    "subnet-09c9480163c55e6df", # Subnet 2
    "subnet-0d22c9dc956e5bc44"  # Subnet 3
  ]
}

# variable "name" {
#   description = "The name of the EFS file system"
#   type        = string
# }

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "encrypted" {
  description = "If true, the file system will be encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "If set, use a specific KMS key"
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "Lifecycle Policy for the EFS Filesystem"
  type = list(object({
    transition_to_ia = string
  }))
  default = []
}

variable "performance_mode" {
  description = "The file system performance mode."
  type        = string
  default     = null
}

variable "throughput_mode" {
  description = "Throughput mode for the file system."
  type        = string
  default     = null
}

variable "provisioned_throughput_in_mibps" {
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned."
  type        = string
  default     = null
}
