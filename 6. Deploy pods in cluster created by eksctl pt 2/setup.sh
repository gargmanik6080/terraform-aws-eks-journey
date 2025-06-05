set -eu

eksctl create cluster \
  --name my-test-cluster \
  --region us-west-2 \
  --nodes 5 \
  --node-type m3.medium \
  --managed

kubectl apply -f frontend.yaml
kubectl apply -f backend.yaml
kubectl apply -f svc-frontend.yaml
kubectl apply -f svc-backend.yaml

###
# kubectl run curlpod -it --rm --image=curlimages/curl:latest -- /bin/sh


# aws ec2 describe-instances \
#   --filters "Name=private-ip-address,Values=192.168.91.163" \
#   --query "Reservations[*].Instances[*].PublicDnsName" \
#   --output text


eksctl utils associate-iam-oidc-provider \
  --region us-west-2 \
  --cluster my-test-cluster \
  --approve


# eksctl create iamserviceaccount \
#     --cluster=my-test-cluster \
#     --namespace=kube-system \
#     --name=aws-load-balancer-controller \
#     --attach-policy-arn=arn:aws:iam::997489286992:policy/AWSLoadBalancerControllerIAMPolicy \
#     --override-existing-serviceaccounts \
#     --region us-west-2 \
#     --approve

# helm repo add eks https://aws.github.io/eks-charts
# helm repo update eks


# helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#   -n kube-system \
#   --set clusterName=my-test-cluster \
#   --set serviceAccount.create=true \
#   --set serviceAccount.name=aws-load-balancer-controller \
#   --version 1.13.0


#   eksctl create iamserviceaccount \
#     --cluster=my-test-cluster \
#     --namespace=kube-system \
#     --name=aws-load-balancer-controller \
#     --attach-policy-arn=arn:aws:iam::735234585484:policy/AWSLoadBalancerControllerIAMPolicy \
#     --override-existing-serviceaccounts \
#     --region us-west-2 \
#     --approve



#####

# eksctl utils associate-iam-oidc-provider \
#     --region us-west-2 \    
#     --cluster my-test-cluster \    
#     --approve

# curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json

aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')" \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn"

aws iam get-instance-profile \
  --instance-profile-name eks-86cb9aa0-a6b5-0898-dd16-8d9d9fe2e7b2 \
  --query "InstanceProfile.Roles[0].RoleName" \
  --output text

aws iam attach-role-policy \
  --role-name <> \
  --policy-arn arn:aws:iam::373211957869:policy/AWSLoadBalancerControllerIAMPolicy


helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-test-cluster \
  --set serviceAccount.create=true \
  --set enableShield=false \
  --set enableWaf=false \
  --set enableWafv2=false

## add cred in pod 
# kubectl edit deployment aws-load-balancer-controller -n kube-system

# ```
# spec:
#   containers:
#     - name: controller
#       env:
#         - name: AWS_ACCESS_KEY_ID
#           value: <your-access-key>
#         - name: AWS_SECRET_ACCESS_KEY
#           value: <your-secret-key>
#         - name: AWS_REGION
#           value: us-west-2
# ```

kubectl apply -f frontend-ingress.yaml
