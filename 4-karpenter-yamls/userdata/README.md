## Deploy the Karpenter NodePools

[Examples userdata Link:](https://karpenter.sh/docs/concepts/nodeclasses/#specuserdata)

- The EC2NodeClass [big-ebs-100g] has already been deployed with the tofu stack
- Next will be to apply the yamls: 

```sh
cd after-terraform-yamls
```

```sh
kubectl apply -f 1.1-zone-gpu-nodepool-EC2NodeClass.yaml  
kubectl apply -f 2.1-zone-Cpu-nodepool-EC2NodeClass.yaml  
kubectl apply -f 3.1-shared-worker-nodepool-EC2NodeClass.yaml
kubectl apply -f 4.1-video-cpu-nodepool-EC2NodeClass.yaml      
kubectl apply -f 5.1-video-gpu-nodepool-EC2NodeClass.yaml
kubectl apply -f 6.1-video-match-cpu-nodepool-EC2NodeClass.yaml
```

For the userdata example, after deploying, you can confirm the Kubernetes settings have been added to the user data of the instance by running this command:

```sh
aws ec2 describe-instance-attribute \
  --instance-id $(aws ec2 describe-instances \
  --filters "Name=tag:karpenter.sh/nodepool,Values=pixies-userdata" \
  --output text --query 'Reservations[0].Instances[0].InstanceId') \
  --attribute userData --query 'UserData.Value' --output text | base64 --decode
```

