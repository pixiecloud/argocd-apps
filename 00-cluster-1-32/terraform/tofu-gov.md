# OPENTOFU DOCUMENTATION
- Major different between Gov and Commercial
  - Karpenter public repo is not allowed: Karpenter chart will have to be installed after cluster creates.
  
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

You might see the following error if the role has already been successfully created. You don't need to worry about this error, you simply had to run the above command to make sure you have the service-linked role to launch Spot instances:

An error occurred (InvalidInput) when calling the CreateServiceLinkedRole operation: Service role name AWSServiceRoleForEC2Spot has been taken in this account, please try a different suffix.
HOTE: Once complete (after waiting about 15 minutes), run the following command to update the `kube.config` file to interact with the cluster through `kubectl`:

```sh
aws eks --region us-east-1 update-kubeconfig --name pixies-production-cluster
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

## 01-after-terraform - Deploy more resources
Next: Deploy the default Karpenter NodePool, and deploy any blueprint you want to test.


NOTE TO SELF 11/18 - COLLINs continue editing documentation

### 1-deploy-vault-to-test-efs  

### 2-test-argo  
Grab the argo token:

```sh
kubectl -n argo exec $( kubectl get pods -n argo -o jsonpath='{.items[0].metadata.name}' ) -- argo auth token
```

### 3-modify-auth-role-tofu  

### 4-fix-role-sa  


### 5-deploy-karpenter-yamls - Deploy a Karpenter Default EC2NodeClass and NodePool
- The EC2NodeClass [big-ebs-100g] has already been deployed with the tofu stack
- Next will be to apply the yamls: 

```sh
cd 01-after-terraform/1-deploy-vault-to-test-efs
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
##----------------------------

- Deploy Workloads unto the cluster
    
    - 2.0: Install ArgoWf
    - 2.1: Install and Configure Istio
    - 2.2: install cert -certbot
    - 2.3: Install ArgoCD

### 2.0 install ArgoWF(cli/server)

```sh
curl -sLO https://github.com/argoproj/argo-workflows/releases/download/v3.5.11/argo-linux-amd64.gz

gunzip argo-linux-amd64.gz

chmod +x argo-linux-amd64

mv ./argo-linux-amd64 /usr/local/bin/argo

argo version

kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.11/install.yaml

kubectl -n argo wait deploy --all --for condition=Available --timeout 2m
```

GET AUTH LOGIN:

[Argo-Workflow Link:](https://ad066e5424f5e4f929d5dcdac34b1473-2126457775.us-east-1.elb.amazonaws.com:2746) #(http://argo.pixies.s3gis.be:2746/)

Obtain Login Token from Cli:

```SH
kubectl -n argo exec $( kubectl get pods -n argo -o jsonpath='{.items[0].metadata.name}' ) -- argo auth token
```

#### 2.1 Install and Configure Istio

1. Download the chart:

```sh
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm search repo istio
```

3. Mkdir for Istio Helm charts:

```sh
mkdir svc-mersh-istio
cd svc-mersh-istio/
helm pull istio/istiod --untar=true
helm pull istio/base --untar=true
helm pull istio/gateway --untar=true
mv gateway ingressgateway
mv base istio-base
```

4. Install the charts:

```sh
kubectl create ns istio-system
helm install istio-base -n istio-system istio-base
helm install istiod -n istio-system istiod
helm install ingressgateway -n istio-system ingressgateway
kubectl -n istio-system get po
```

5. Make a seperate for all the virtual-svc and gateway yamls:

```sh
mkdir vs-gw-files
cd vs-gw-files/
kubectl apply -f gateway.yaml
kubectl apply -f vs ...
```

6. Obtain the Istio Gatewaay LB and save the CName Record EX:


```sh
EX::: --> aaaaaaaaaaaaaaaaaaaace7c0-1341964332.us-east-1.elb.amazonaws.com
```

#### 2.2: Install cert - certbot


1. create the cert and secure the record:

```sh
sudo certbot certonly --manual -d *.xxxx.com --agree-tos --manual-public-ip-logging-ok --preferred-challenges dns-01 --server https://acme-v02.api.letsencrypt.org/directory --email=collins.afanwi@xxxx.com --rsa-key-size 4096
```

2. Register text record unto Route53, obtained from precious step - EX:

```sh
EX:::  -->     _acme-challenge.xxxx.com.
                6j4Cp-UTkaj.................................
```

3. CREATE A secret with the TLS Key n cert:

```sh
sudo kubectl create secret tls gateway-certs --cert=/etc/letsencrypt/live/xxxx.com/fullchain.pem --key=/etc/letsencrypt/live/xxxx.com/privkey.pem -n istio-system --dry-run=client -o yaml > xxxx-tls-secret.yaml

k -n istio-system  apply -f xxxx-tls-secret.yaml
```

#### 2.3: Install ArgoCD

[LINK:](https://argo-cd.readthedocs.io/en/stable/getting_started/#:~:text=kubectl%20apply%20-n%20argocd%20-f#:~:text=kubectl%20apply%20-n%20argocd%20-f)

1. Download the latest yaml from the official doc with wget:

```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
k -n argocd get all
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

2.  configure UI:

```sh
k -n argocd apply -f argocd-config-ui.yaml 
k -n argocd rollout restart deploy,sts
k -n argocd get po
```

3. Apply the VS for Argocd:

```sh
k -n argocd apply -f argocd-vs.yaml
```

4. Get the login secret:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

<!-- admin
O70jdu3u5aRUojUE -->

## 3. Setup Storage: EFS

## 4. Setup GitOps 

- Setup AWS and ArgoCD Auth
- Setup and Configure ArgoCD Deployment Repo

***4.1 Setup AWS and ArgoCD Auth***


***4.2 Setup and Configure ArgoCD Deployment Repo***

Workloads in the REPO Stack:

- AgroWF
- TileDB
- MQTT
- SonarQube
- PostGis
- ELK - Optional


## DEPLOY DOCUMEN
```sh
k create deploy pixies-doc --image 126924000548.dkr.ecr.us-east-1.amazonaws.com/pixies-internal-documentation:2.2.11 --port=8000
k expose deploy pixies-doc --port=8080 --target-port=8000 --type=LoadBalancer
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