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
  --filters "Name=private-ip-address,Values=192.168.73.68" \
  --query "Reservations[*].Instances[*].PublicDnsName" \
  --output text
