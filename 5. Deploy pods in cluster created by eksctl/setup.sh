aws configure

eksctl create cluster \
  --name my-test-cluster \
  --region us-west-2 \
  --nodes 5 \
  --node-type m3.medium \
  --managed

k apply -f frontend.yaml
k apply -f backend.yaml
k apply -f svc-frontend.yaml
k apply -f svc-backend.yaml

###
# Commands used for testings

# eksctl create nodegroup \
#   --cluster my-test-cluster \
#   --name large-ng \
#   --node-type m3.medium \
#   --nodes 2 \
#   --nodes-min 1 \
#   --nodes-max 3



# kubectl port-forward service/omnixo-frontend 8080:8080

# kubectl run curlpod -it --rm --image=curlimages/curl:latest -- /bin/sh