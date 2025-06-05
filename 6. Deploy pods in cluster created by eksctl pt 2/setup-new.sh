#!/bin/bash

# AWS Load Balancer Controller Setup Script with Comprehensive Logging
# This script sets up an EKS cluster with AWS Load Balancer Controller for ingress

set -euo pipefail

# Color codes for better logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
CLUSTER_NAME="my-test-cluster"
REGION="us-west-2"
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
CONTROLLER_NAME="aws-load-balancer-controller"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed. Please install it before running this script."
        exit 1
    fi
}

# Function to get AWS Account ID
get_account_id() {
    aws sts get-caller-identity --query Account --output text
}
# Prerequisite checks
log_info "Checking prerequisites..."
check_command "eksctl"
check_command "kubectl"
check_command "helm"
check_command "aws"

ACCOUNT_ID=$(get_account_id)
log_info "Using AWS Account ID: $ACCOUNT_ID"

: '
# Step 1: Create EKS Cluster
log_info "Creating EKS cluster: $CLUSTER_NAME"
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --nodes 5 \
  --node-type m3.medium \
  --managed

if [ $? -eq 0 ]; then
    log_success "EKS cluster created successfully"
else
    log_error "Failed to create EKS cluster"
    exit 1
fi

# Step 2: Deploy Applications
log_info "Deploying frontend and backend applications..."
kubectl apply -f frontend.yaml
kubectl apply -f backend.yaml
kubectl apply -f svc-frontend.yaml
kubectl apply -f svc-backend.yaml

if [ $? -eq 0 ]; then
    log_success "Applications deployed successfully"
    log_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod --all --timeout=300s
else
    log_error "Failed to deploy applications"
    exit 1
fi
'

# Step 3: Wait for cluster to be fully ready
log_info "Waiting for cluster to be fully ready..."
CLUSTER_STATUS=""
for i in {1..30}; do
    CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.status' --output text 2>/dev/null || echo "NOTFOUND")
    if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
        log_success "Cluster is ACTIVE and ready"
        break
    fi
    log_info "Cluster status: $CLUSTER_STATUS - waiting... (attempt $i/30)"
    sleep 20
done

if [ "$CLUSTER_STATUS" != "ACTIVE" ]; then
    log_error "Cluster failed to become ACTIVE within timeout"
    log_info "Current status: $CLUSTER_STATUS"
    log_info "You may need to wait longer or check AWS Console"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verify kubectl connectivity
log_info "Verifying kubectl connectivity..."
if ! kubectl get nodes &>/dev/null; then
    log_error "kubectl cannot connect to cluster"
    log_info "Try running: aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
    exit 1
fi

# Step 4: Create IAM Policy and Attach to Worker Nodes
log_info "Setting up IAM policy for Load Balancer Controller..."
log_info "Note: IAM policy includes comprehensive describe permissions for ALB, EC2, Route53, EKS, and more"

# Create IAM policy
log_info "Creating IAM policy: $POLICY_NAME"
aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://iam-policy.json 2>/dev/null && {
    log_success "IAM policy created successfully"
} || {
    log_warning "Policy $POLICY_NAME already exists, continuing..."
}

POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"
log_info "Using policy ARN: $POLICY_ARN"

# Verify policy exists
if ! aws iam get-policy --policy-arn $POLICY_ARN &>/dev/null; then
    log_error "Policy $POLICY_ARN does not exist"
    log_info "Please create the policy manually or check the iam-policy.json file"
    exit 1
fi

# Get worker node instance profile and role
log_info "Finding worker node IAM role..."
WORKER_NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
log_info "Worker node IP: $WORKER_NODE_IP"

INSTANCE_PROFILE_ARN=$(aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$WORKER_NODE_IP" \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn" \
  --output text)

if [ -z "$INSTANCE_PROFILE_ARN" ]; then
    log_error "Could not find instance profile for worker node"
    exit 1
fi

INSTANCE_PROFILE_NAME=$(echo $INSTANCE_PROFILE_ARN | cut -d'/' -f2)
log_info "Instance profile: $INSTANCE_PROFILE_NAME"

WORKER_ROLE_NAME=$(aws iam get-instance-profile \
  --instance-profile-name $INSTANCE_PROFILE_NAME \
  --query "InstanceProfile.Roles[0].RoleName" \
  --output text)

log_info "Worker role name: $WORKER_ROLE_NAME"

# Attach policy to worker node role
log_info "Attaching Load Balancer Controller policy to worker node role..."
if aws iam attach-role-policy \
  --role-name $WORKER_ROLE_NAME \
  --policy-arn $POLICY_ARN; then
    log_success "Policy attached to worker node role successfully"
else
    log_error "Failed to attach policy to worker node role"
    exit 1
fi

# Step 5: Create Basic Service Account
log_info "Creating basic service account..."
kubectl create serviceaccount $CONTROLLER_NAME -n kube-system --dry-run=client -o yaml | kubectl apply -f -
log_success "Service account created"

# Step 6: Add Helm Repository
log_info "Adding EKS Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

if [ $? -eq 0 ]; then
    log_success "Helm repository added and updated"
else
    log_error "Failed to add Helm repository"
    exit 1
fi

# Step 7: Install AWS Load Balancer Controller
log_info "Installing AWS Load Balancer Controller..."

if [ "${USE_MANUAL_CREDS:-false}" = true ]; then
    log_warning "Installing controller without IAM roles for service accounts"
    log_warning "You'll need to add AWS credentials manually to the deployment"
    
    helm upgrade --install $CONTROLLER_NAME eks/aws-load-balancer-controller \
      -n kube-system \
      --set clusterName=$CLUSTER_NAME \
      --set serviceAccount.create=false \
      --set serviceAccount.name=$CONTROLLER_NAME \
      --set enableShield=false \
      --set enableWaf=false \
      --set enableWafv2=false
    
    if [ $? -eq 0 ]; then
        log_success "AWS Load Balancer Controller installed successfully"
        log_warning "⚠️  IMPORTANT: You need to add AWS credentials to the controller deployment"
        log_info "Run this command to edit the deployment:"
        log_info "kubectl edit deployment $CONTROLLER_NAME -n kube-system"
        log_info ""
        log_info "Add these environment variables to the controller container:"
        log_info "  env:"
        log_info "    - name: AWS_ACCESS_KEY_ID"
        log_info "      value: <your-access-key>"
        log_info "    - name: AWS_SECRET_ACCESS_KEY"
        log_info "      value: <your-secret-key>"
        log_info "    - name: AWS_REGION"
        log_info "      value: $REGION"
    else
        log_error "Failed to install AWS Load Balancer Controller"
        exit 1
    fi
else
    helm upgrade --install $CONTROLLER_NAME eks/aws-load-balancer-controller \
      -n kube-system \
      --set clusterName=$CLUSTER_NAME \
      --set serviceAccount.create=false \
      --set serviceAccount.name=$CONTROLLER_NAME \
      --set enableShield=false \
      --set enableWaf=false \
      --set enableWafv2=false

    if [ $? -eq 0 ]; then
        log_success "AWS Load Balancer Controller installed successfully"
    else
        log_error "Failed to install AWS Load Balancer Controller"
        exit 1
    fi
fi

# Step 8: Wait for controller to be ready
log_info "Waiting for controller to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/$CONTROLLER_NAME -n kube-system

if [ $? -eq 0 ]; then
    log_success "Controller is ready"
else
    log_warning "Controller might not be fully ready, but continuing..."
fi

# Verify controller is running
log_info "Verifying controller status..."
kubectl get deployment -n kube-system $CONTROLLER_NAME
kubectl logs -n kube-system deployment/$CONTROLLER_NAME --tail=10

# Step 9: Deploy Ingress
log_info "Deploying frontend ingress..."
kubectl apply -f frontend-ingress.yaml

if [ $? -eq 0 ]; then
    log_success "Ingress deployed successfully"
else
    log_error "Failed to deploy ingress"
    exit 1
fi

# Step 9.1: Force reconciliation and restart controller to pick up new permissions
log_info "Forcing ingress reconciliation to apply updated IAM permissions..."
kubectl annotate ingress frontend-ingress alb.ingress.kubernetes.io/force-reconcile="$(date)" --overwrite

log_info "Restarting AWS Load Balancer Controller to ensure it picks up new IAM permissions..."
kubectl rollout restart deployment/aws-load-balancer-controller -n kube-system

log_info "Waiting for controller to restart..."
kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=120s

if [ $? -eq 0 ]; then
    log_success "Controller restarted successfully"
else
    log_warning "Controller restart may have taken longer than expected, but continuing..."
fi

# Step 10: Wait for ALB to be provisioned and get its DNS name
log_info "Waiting for ALB to be provisioned (this may take 3-5 minutes)..."
log_info "You can check ALB creation progress in AWS Console > EC2 > Load Balancers"

ALB_DNS=""
for i in {1..20}; do
    ALB_DNS=$(kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ ! -z "$ALB_DNS" ]; then
        break
    fi
    log_info "Waiting for ALB... (attempt $i/20)"
    sleep 15
done

if [ ! -z "$ALB_DNS" ]; then
    log_success "ALB provisioned successfully!"
    log_success "ALB DNS Name: $ALB_DNS"
    log_info "You can access your application at: http://$ALB_DNS"
    
    # Test ALB connectivity
    log_info "Testing ALB connectivity..."
    sleep 30  # Give ALB a moment to be fully ready
    if curl -s --connect-timeout 10 http://$ALB_DNS > /dev/null; then
        log_success "ALB is responding to requests!"
    else
        log_warning "ALB may not be fully ready yet. Try accessing it in a few minutes."
    fi
else
    log_warning "ALB not ready yet. Check ingress status with: kubectl describe ingress frontend-ingress"
fi

# Final verification
log_info "Performing final verification..."
echo ""
echo "=== Cluster Status ==="
kubectl get nodes
echo ""
echo "=== Pods Status ==="
kubectl get pods
echo ""
echo "=== Services Status ==="
kubectl get services
echo ""
echo "=== Ingress Status ==="
kubectl get ingress
kubectl describe ingress frontend-ingress
echo ""
echo "=== Load Balancer Controller Status ==="
kubectl get deployment -n kube-system $CONTROLLER_NAME

log_success "Setup completed successfully!"
echo ""
echo "=== Next Steps ==="
if [ ! -z "$ALB_DNS" ]; then
    echo "✅ Frontend: http://$ALB_DNS"
    echo "✅ Backend API: http://$ALB_DNS/move/test"
    echo ""
    echo "Test commands:"
    echo "  curl http://$ALB_DNS"
    echo "  curl http://$ALB_DNS/move/test"
else
    echo "Get ALB DNS with: kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
fi

# Optional: Run a curl pod for testing
echo ""
read -p "Do you want to create a curl pod for testing? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Creating curl pod for testing..."
    echo "Commands to try inside the curl pod:"
    echo "  curl omnixo-frontend.default.svc.cluster.local"
    echo "  curl omnixo-server.default.svc.cluster.local:3030/move/test"
    kubectl run curlpod --image=curlimages/curl:latest --rm -it --restart=Never -- /bin/sh
fi

log_info "Script execution completed. Check logs above for any issues."
echo ""
echo "=== Troubleshooting Tips ==="
echo "If ALB fails to create:"
echo "1. Check IAM permissions: kubectl describe ingress frontend-ingress"
echo "2. Force reconciliation: kubectl annotate ingress frontend-ingress alb.ingress.kubernetes.io/force-reconcile=\"\$(date)\" --overwrite"
echo "3. Restart controller: kubectl rollout restart deployment/aws-load-balancer-controller -n kube-system"
echo "4. Check controller logs: kubectl logs -n kube-system deployment/aws-load-balancer-controller"
echo ""
echo "Common IAM issues resolved by this script:"
echo "✅ elasticloadbalancing:AddTags permission"
echo "✅ elasticloadbalancing:DescribeListenerAttributes permission" 
echo "✅ Comprehensive describe permissions for all AWS services"
echo "✅ Direct IAM policy attachment to worker node roles (no OIDC required)"
