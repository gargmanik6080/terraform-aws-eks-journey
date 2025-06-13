# Exercise 6: Deploy Pods with AWS Load Balancer Controller (EKS Part 2)

This exercise builds upon Exercise 5 by adding **AWS Load Balancer Controller** to enable ingress functionality, allowing external traffic to reach your applications through an Application Load Balancer (ALB).

## 🎯 Learning Objectives

- Set up AWS Load Balancer Controller in EKS
- Configure IAM policies for ALB management
- Deploy applications with ingress configuration
- Understand the difference between NodePort and ALB ingress
- Learn ALB annotations and routing rules

## 📋 Prerequisites

- Completed Exercise 5 (EKS cluster setup)
- `eksctl` CLI installed
- `kubectl` CLI installed
- `helm` CLI installed
- AWS CLI configured with appropriate permissions

## 🏗️ Architecture Overview

```
Internet → ALB → EKS Worker Nodes → Pods
                    ↑
           Load Balancer Controller
           (manages ALB lifecycle)
```

The AWS Load Balancer Controller watches for Kubernetes Ingress resources and automatically provisions/configures AWS Application Load Balancers.

## 🚀 Deployment Steps

### Step 1: Create EKS Cluster

If you haven't already created a cluster from Exercise 5:

```bash
eksctl create cluster \
  --name my-test-cluster \
  --region us-west-2 \
  --nodes 5 \
  --node-type m3.medium \
  --managed
```

### Step 2: Deploy Applications

Deploy the frontend and backend applications:

```bash
kubectl apply -f frontend.yaml
kubectl apply -f backend.yaml
kubectl apply -f svc-frontend.yaml
kubectl apply -f svc-backend.yaml
```

### Step 3: Set up IAM for Load Balancer Controller

The setup script (`setup-new.sh`) uses a **direct IAM policy attachment** approach instead of the complex OIDC provider setup. This avoids common connectivity issues with OIDC endpoints.

#### How It Works

1. **Find Worker Node**: Gets the IP of the first worker node
2. **Get Instance Profile**: Uses EC2 API to find the IAM instance profile
3. **Extract Role Name**: Gets the IAM role name from the instance profile
4. **Attach Policy**: Directly attaches the custom ALB policy to the worker node role

```bash
# 1. Get worker node IP
WORKER_NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# 2. Find instance profile
INSTANCE_PROFILE_ARN=$(aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$WORKER_NODE_IP" \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn" \
  --output text)

# 3. Get role name from instance profile
WORKER_ROLE_NAME=$(aws iam get-instance-profile \
  --instance-profile-name $INSTANCE_PROFILE_NAME \
  --query "InstanceProfile.Roles[0].RoleName" \
  --output text)

# 4. Attach policy to role
aws iam attach-role-policy \
  --role-name $WORKER_ROLE_NAME \
  --policy-arn $POLICY_ARN
```

### Step 4: Create IAM Policy

Create the IAM policy using the provided `iam-policy.json`:

```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
```

#### Enhanced IAM Policy Features

The comprehensive IAM policy includes:

- **60+ describe permissions** across EC2, ELB, Route53, EKS services
- **Fixed `elasticloadbalancing:AddTags` permission issues**
- **Fixed `elasticloadbalancing:DescribeListenerAttributes` permission issues**
- **Comprehensive permissions for**:
  - Application Load Balancer management
  - VPC and subnet operations
  - Security group management
  - EC2 instance operations
  - Route53 (for DNS)
  - WAF and Shield (for security)

### Step 5: Install AWS Load Balancer Controller

Add the EKS Helm repository and install the controller:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-test-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Step 6: Verify Controller Installation

Check if the controller is running:

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Step 7: Deploy Ingress

Apply the ingress configuration:

```bash
kubectl apply -f frontend-ingress.yaml
```

### Step 8: Verify ALB Creation

Check ingress status:

```bash
kubectl get ingress frontend-ingress
kubectl describe ingress frontend-ingress
```

The ALB DNS name will appear in the `ADDRESS` field after a few minutes.

## 📁 File Descriptions

### `iam-policy.json`
Comprehensive IAM policy with permissions for:
- **ELB Operations**: Create, modify, delete load balancers and target groups
- **EC2 Permissions**: VPC, subnet, security group management
- **Certificate Management**: ACM certificate operations
- **WAF Integration**: Web Application Firewall associations
- **Shield Integration**: DDoS protection
- **Service Discovery**: For advanced routing features

### `frontend-ingress.yaml`
Ingress configuration with:
- **ALB Scheme**: `internet-facing` for public access
- **Target Type**: `ip` for direct pod targeting
- **Routing Rules**: 
  - `/` → frontend service (port 80)
  - `/move` and `/api/move` → backend API service (port 3030)
  
### `setup-new.sh`
Automated setup script with commands for the entire deployment process including:
- Cluster creation
- Application deployment
- IAM policy creation and attachment
- ALB controller installation
- Ingress deployment
- Testing and validation

## 🧪 Testing the Deployment

### 1. Get ALB DNS Name

```bash
kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 2. Test Frontend Access

```bash
ALB_DNS=$(kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$ALB_DNS
```

### 3. Test Backend API Access

The backend API only accepts POST requests with JSON data:

```bash
# This will return 405 Method Not Allowed (expected behavior)
curl http://$ALB_DNS/move

# Correct way to test the API
curl -X POST http://$ALB_DNS/move \
  -H "Content-Type: application/json" \
  -d '{
    "board": [null, null, null, null, "X", null, null, null, null],
    "player": "O"
  }'
```

Expected response:
```json
{"newBoard":["O",null,null,null,"X",null,null,null,null],"winner":"None"}
```

### 4. API Path Configuration

- Frontend serves at: `/` (main page) and `/board` (game interface)
- Backend API at: `/move` and `/api/move` (accepts POST with game state)
- Frontend at `/board` calls backend at `/api/move` for game logic

### 5. Browser Testing

Open your browser and navigate to the ALB DNS name to access the application.

## 🔧 Troubleshooting Guide

### ALB Not Created

**Issue**: Ingress shows no ADDRESS after 10+ minutes

**Solutions**:
1. Check controller logs:
   ```bash
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

2. Verify IAM permissions:
   ```bash
   kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
   ```

3. Check subnet tags (ALB needs proper subnet tags):
   ```bash
   aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxx"
   ```

### Controller Pod CrashLoopBackOff

**Issue**: Load balancer controller pods failing to start

**Solutions**:
1. Check OIDC provider:
   ```bash
   aws eks describe-cluster --name my-test-cluster --query cluster.identity.oidc.issuer
   ```

2. Verify service account annotation:
   ```bash
   kubectl get serviceaccount aws-load-balancer-controller -n kube-system -o yaml
   ```

### Target Health Issues

**Issue**: ALB created but targets unhealthy

**Solutions**:
1. Check pod readiness:
   ```bash
   kubectl get pods -o wide
   kubectl describe pod <pod-name>
   ```

2. Verify security groups allow ALB → Pod traffic

3. Check target group in AWS Console

### IAM Permission Issues

#### Problem 1: Missing `elasticloadbalancing:AddTags` Permission
- **Error**: `User is not authorized to perform: elasticloadbalancing:AddTags`
- **Solution**: Enhanced IAM policy with comprehensive tagging permissions

#### Problem 2: Missing `elasticloadbalancing:DescribeListenerAttributes` Permission  
- **Error**: `User is not authorized to perform: elasticloadbalancing:DescribeListenerAttributes`
- **Solution**: Added comprehensive describe permissions for all ELB operations

## 💡 ALB vs NodePort Comparison

| Feature | NodePort (Exercise 5) | ALB Ingress (Exercise 6) |
|---------|----------------------|-------------------------|
| **Access** | `<node-ip>:<port>` | DNS name |
| **Load Balancing** | Manual/External | AWS ALB |
| **SSL/TLS** | Manual setup | ACM integration |
| **Health Checks** | Basic | Advanced ALB health checks |
| **Cost** | Node resources only | ALB + Node resources |
| **Production Ready** | Limited | Yes |

## 🎓 Learning Questions

1. **What is the difference between `alb.ingress.kubernetes.io/target-type: ip` vs `instance`?**

2. **How would you add SSL/HTTPS to this setup?**

3. **What happens if you delete the Ingress resource?**

4. **How can you configure path-based routing to multiple services?**

5. **What IAM permissions are needed for the Load Balancer Controller?**

6. **How does the controller discover which subnets to use for the ALB?**

7. **What's the difference between `internet-facing` and `internal` ALB schemes?**

## 🧹 Cleanup

### Remove Ingress (keeps cluster)
```bash
kubectl delete ingress frontend-ingress
```

### Remove Load Balancer Controller
```bash
helm uninstall aws-load-balancer-controller -n kube-system
```

### Delete Entire Cluster
```bash
eksctl delete cluster --name my-test-cluster --region us-west-2
```

### Delete IAM Policy
```bash
aws iam delete-policy --policy-arn arn:aws:iam::YOUR-ACCOUNT-ID:policy/AWSLoadBalancerControllerIAMPolicy
```

## 📚 Additional Resources

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [ALB Ingress Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/)
- [EKS Workshop - ALB Ingress](https://www.eksworkshop.com/beginner/130_exposing-service/ingress/)

## ⚠️ Cost Considerations

- **Application Load Balancer**: ~$22.50/month + data processing charges
- **EKS Cluster**: $0.10/hour (~$73/month)
- **EC2 Instances**: 5 × t3.medium (~$185/month)
- **Data Transfer**: Variable based on usage

**Estimated Monthly Cost**: ~$280-300

Always clean up resources after learning to avoid unexpected charges!

## 🎉 Final Status - Success!

The deployment is fully functional with:

| Component | Status | Test Result |
|-----------|--------|-------------|
| **Frontend** | ✅ Working | Returns HTML page correctly |
| **Backend API** | ✅ Working | Returns JSON response correctly |
| **ALB Routing** | ✅ Working | Routes `/` to frontend, `/move` to backend |
| **Method Handling** | ✅ Working | GET/POST routed correctly |
| **IAM Permissions** | ✅ Working | All required permissions in place |

### 📝 Key Learnings
1. **Method-specific routing**: API endpoints can be method-specific (POST only)
2. **Path precedence**: Order matters in ingress path rules
3. **Service discovery**: Internal vs external routing considerations
4. **IAM permissions**: Comprehensive permissions prevent deployment issues
5. **Testing strategy**: Different endpoints require different test approaches

## 🔄 Migration to IRSA (Optional)

For production environments, you can later migrate to IAM Roles for Service Accounts:
1. Set up OIDC provider
2. Create service account with IAM role annotation
3. Remove policy from worker node role
4. Update ALB controller to use new service account

This simplified approach gets you up and running quickly while maintaining the option to enhance security later.
