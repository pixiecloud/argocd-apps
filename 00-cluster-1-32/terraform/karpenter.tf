# Karpenter default EC2NodeClass and NodePool

resource "kubectl_manifest" "karpenter_default_ec2_node_class" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  role: "${local.node_iam_role_name}"
  amiSelectorTerms: 
  - alias: al2@latest
  securityGroupSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${local.name}
  subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${local.name}
  tags:
    IntentLabel: apps
    KarpenterNodePoolName: default
    NodeType: default
    intent: apps
    karpenter.sh/discovery: ${local.name}
    project: pixies-karpenter
YAML
  depends_on = [
    module.eks.cluster,
    module.eks_blueprints_addons.karpenter,
  ]
}

resource "kubectl_manifest" "karpenter_default_node_pool" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default 
spec:  
  template:
    metadata:
      labels:
        intent: apps
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: In
          values: ["4", "8", "16", "32", "48", "64"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r", "i", "d"]
      nodeClassRef:
        name: default
        group: karpenter.k8s.aws
        kind: EC2NodeClass
      kubelet:
        containerRuntime: containerd
        systemReserved:
          cpu: 100m
          memory: 100Mi
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
    
YAML
  depends_on = [
    module.eks.cluster,
    module.eks_blueprints_addons.karpenter,
    kubectl_manifest.karpenter_default_ec2_node_class,
  ]
}

## collins adding  EC2NodeClass ###################
resource "kubectl_manifest" "karpenter_bigebs_ec2_node_class" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: big-ebs-100g
spec:
  role: "${local.node_iam_role_name}"
  amiSelectorTerms: 
  - alias: al2@latest
  securityGroupSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${local.name}
  subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${local.name}
  tags:
    IntentLabel: apps
    KarpenterNodePoolName: big-ebs-100g
    NodeType: big-ebs
    intent: apps
    karpenter.sh/discovery: ${local.name}
    project: pixies-karpenter
YAML
  depends_on = [
    module.eks.cluster,
    module.eks_blueprints_addons.karpenter,
  ]
}

# ############# collins adding node pools  below ####################
# resource "kubectl_manifest" "karpenter_shared_worker_node_pool" {
#   yaml_body = <<YAML
# apiVersion: karpenter.sh/v1
# kind: NodePool
# metadata:
#   name: shared-worker
# spec:
#   template:
#     metadata:
#       labels:
#         pool-type: shared-pipeline-pool
#         node-type: worker
#     spec:
#       requirements:
#         - key: kubernetes.io/arch
#           operator: In
#           values: ["amd64"]
#         - key: kubernetes.io/os
#           operator: In
#           values: ["linux"]
#         - key: karpenter.sh/capacity-type
#           operator: In
#           values: ["on-demand"]
#         - key: karpenter.k8s.aws/instance-category
#           operator: In
#           values: ["m"]
#       nodeClassRef:
#         name: big-ebs-100g
#         group: karpenter.k8s.aws
#         kind: EC2NodeClass
#       kubelet:
#         containerRuntime: containerd
#         systemReserved:
#           cpu: 100m
#           memory: 100Mi
#   disruption:
#     consolidationPolicy: WhenEmptyOrUnderutilized
#     consolidateAfter: 1m

# YAML
#   depends_on = [
#     module.eks.cluster,
#     module.eks_blueprints_addons.karpenter,
#     kubectl_manifest.karpenter_bigebs_ec2_node_class, # Ensure the EC2NodeClass is created first
#   ]
# }
# #####################################################################################################





