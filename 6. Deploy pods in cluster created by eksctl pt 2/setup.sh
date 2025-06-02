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
kubectl apply -f frontend-ingress.yaml

###
# kubectl run curlpod -it --rm --image=curlimages/curl:latest -- /bin/sh


aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=192.168.70.170" \
  --query "Reservations[*].Instances[*].PublicDnsName" \
  --output text


# eksctl utils associate-iam-oidc-provider \
#   --region us-west-2 \
#   --cluster my-test-cluster \
#   --approve


# eksctl create iamserviceaccount \
#     --cluster=my-test-cluster \
#     --namespace=kube-system \
#     --name=aws-load-balancer-controller \
#     --attach-policy-arn=arn:aws:iam::997489286992:policy/AWSLoadBalancerControllerIAMPolicy \
#     --override-existing-serviceaccounts \
#     --region us-west-2 \
#     --approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update eks


helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-test-cluster \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --version 1.13.0