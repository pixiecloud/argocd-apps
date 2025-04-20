# OPENTOFU DOCUMENTATION
prerequisites:

## 00-cluster-1-31 - Deploying the EKS Cluster using OpenTofu

To create the cluster, clone this repository and then run the following commands:

```sh
cd 00-cluster-1-31/terraform
helm registry logout public.ecr.aws
export TF_VAR_region=$AWS_REGION
tofu init
tofu apply -target="module.vpc" -auto-approve
tofu apply -target="module.vpc_cni_irsa" -auto-approve
tofu apply -target="module.eks" -auto-approve
tofu apply --auto-approve
```

Before you continue, you need to enable your AWS account to launch Spot instances if you haven't launch any yet:

```sh
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com || true
```

```sh
aws eks --region us-east-1 update-kubeconfig --name pixies--production-cluster
```

Make sure you can interact with the cluster and that the Karpenter pods are running:

```sh
$ kubectl get pods -n karpenter

NAME                        READY   STATUS    RESTARTS   AGE
karpenter-9d586dc9c-dvfz8   1/1     Running   0          13m
karpenter-9d586dc9c-mf6xs   1/1     Running   0          13m
```

See Links to:
[EC2NodeClass - formelly AWSNodeTemplate ](https://karpenter.sh/preview/concepts/nodeclasses/) 
[NodePool - Formelly Provisioner](https://karpenter.sh/docs/concepts/nodepools/) 

## after-terraform - Deploy more resources
Next: Deploy the default Karpenter NodePool, and deploy any blueprint you want to test.
- The EC2NodeClass [big-ebs-100g] has already been deployed with the tofu stack
- Next will be to apply the yamls: 

```sh
cd 4-karpenter-yamls
```

```sh
kubectl apply -f 1.1-zone-gpu-nodepool-EC2NodeClass.yaml  
kubectl apply -f 2.1-zone-Cpu-nodepool-EC2NodeClass.yaml  
kubectl apply -f 3.1-shared-worker-nodepool-EC2NodeClass.yaml
kubectl apply -f 4.1-video-cpu-nodepool-EC2NodeClass.yaml      
kubectl apply -f 5.1-video-gpu-nodepool-EC2NodeClass.yaml
kubectl apply -f 6.1-video-match-cpu-nodepool-EC2NodeClass.yaml
```

You can see that the [NodePool] and [EC2NodeClass] has been deployed by running this:

```sh
kubectl get nodepool
kubectl get ec2nodeclass
```

Throughout all the blueprints, you might need to review Karpenter logs using the command:

```sh
kubectl -n karpenter logs -l app.kubernetes.io/name=karpenter --all-containers=true -f --tail=20"
```

##### METDATE -Collins
#### Delete

```sh
kubectl get nodeclaim -A

kubectl delete --all nodeclaim
kubectl delete --all nodepool
kubectl delete --all ec2nodeclass
export TF_VAR_region=$AWS_REGION
tofu destroy -target="module.eks_blueprints_addons" --auto-approve
tofu destroy -target="module.eks" --auto-approve
tofu destroy --auto-approve
```

######  If you face issues: here are some troubleshooting commands
## helm failed
kubectl rollout restart deployment aws-load-balancer-controller -n kube-system
terraform apply  --auto-approve


---------------------
helm status karpenter -n karpenter
kubectl get events -n karpenter --sort-by='.metadata.creationTimestamp'
kubectl get serviceaccount karpenter -n karpenter -o yaml


helm history karpenter -n karpenter
helm get all karpenter -n karpenter

## just uninstall the chart, reinstall and then reapply the terraform
helm uninstall karpenter -n karpenter
terraform apply

ORRR

helm install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version 1.0.1 \
  --namespace karpenter \
  --create-namespace


kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

kubectl get svc -n kube-system aws-load-balancer-webhook-service
kubectl describe svc -n kube-system aws-load-balancer-webhook-service
helm uninstall karpenter -n karpenter
terraform apply


### after karpenter installed, install webhooks dus to webhook issues
kubectl describe secret karpenter-cert kubectl describe secret karpenter-cert -n <namespace>
kubectl describe deployment karpenter kubectl describe secret karpenter-cert -n <namespace>

kubectl get mutatingwebhookconfigurations
kubectl get validatingwebhookconfigurations
kubectl get serviceaccount -n karpenter
kubectl get rolebinding -n karpenter
kubectl get serviceaccount karpenter -n karpenter -o yaml

kubectl get events -n karpenter
kubectl get crd | grep karpenter
kubectl get deployment karpenter -n karpenter -o=jsonpath='{.spec.template.spec.containers[0].image}'

ORRR

helm install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version 1.0.1 \
  --namespace karpenter \
  --create-namespace


kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

kubectl get svc -n kube-system aws-load-balancer-webhook-service
kubectl describe svc -n kube-system aws-load-balancer-webhook-service
helm uninstall karpenter -n karpenter
terraform apply


### after karpenter installed, install webhooks dus to webhook issues
kubectl describe secret karpenter-cert kubectl describe secret karpenter-cert -n <namespace>
kubectl describe deployment karpenter kubectl describe secret karpenter-cert -n <namespace>

kubectl get mutatingwebhookconfigurations
kubectl get validatingwebhookconfigurations
kubectl get serviceaccount -n karpenter
kubectl get rolebinding -n karpenter
 kubectl get serviceaccount karpenter -n karpenter -o yaml

kubectl get events -n karpenter
kubectl get crd | grep karpenter
kubectl get deployment karpenter -n karpenter -o=jsonpath='{.spec.template.spec.containers[0].image}'

kubectl get ec2nodeclass
kubectl get nodepool


kubectl edit configmap aws-auth -n kube-system

##