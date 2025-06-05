# Setup Script Summary - Simplified IAM Approach

## What the Script Does

The `setup-new.sh` script has been simplified to use a **direct IAM policy attachment** approach instead of the complex OIDC provider setup. This avoids common connectivity issues with OIDC endpoints.

## Key Changes Made

### ✅ Simplified IAM Approach
- **Removed**: Complex OIDC provider association logic
- **Added**: Direct IAM policy attachment to EKS worker node roles
- **Result**: More reliable setup with fewer failure points

### 🔍 How It Works

1. **Find Worker Node**: Gets the IP of the first worker node
2. **Get Instance Profile**: Uses EC2 API to find the IAM instance profile
3. **Extract Role Name**: Gets the IAM role name from the instance profile
4. **Attach Policy**: Directly attaches the custom ALB policy to the worker node role

### 📋 Step-by-Step Process

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

## Benefits of This Approach

### ✅ Advantages
- **Simpler Setup**: No OIDC provider needed
- **More Reliable**: Avoids network connectivity issues with OIDC endpoints
- **Faster**: No waiting for OIDC provider to become available
- **Direct**: Policy attached directly to existing worker node role

### ⚠️ Considerations
- **Scope**: Policy applies to all workloads on worker nodes (not just ALB controller)
- **Security**: Less granular than service account-specific IAM roles
- **Best Practice**: For production, consider using IAM roles for service accounts (IRSA)

## IAM Policy Permissions

The custom policy includes permissions for:
- Application Load Balancer management
- VPC and subnet operations
- Security group management
- EC2 instance operations
- Route53 (for DNS)
- WAF and Shield (for security)

## Usage

Simply run the script:
```bash
chmod +x setup-new.sh
./setup-new.sh
```

The script will:
1. Create EKS cluster
2. Deploy applications
3. Create and attach IAM policy
4. Install ALB controller
5. Deploy ingress
6. Provide ALB DNS for testing

## Troubleshooting

If the script fails:
1. Check AWS credentials: `aws sts get-caller-identity`
2. Verify kubectl: `kubectl get nodes`
3. Check policy exists: `aws iam get-policy --policy-arn arn:aws:iam::ACCOUNT:policy/AWSLoadBalancerControllerIAMPolicy`
4. Manual policy attachment: `aws iam attach-role-policy --role-name ROLE_NAME --policy-arn POLICY_ARN`

## Manual Fixes Incorporated

The setup script now includes fixes for common issues encountered during manual testing:

### 🔧 **IAM Permission Issues Fixed**

#### Problem 1: Missing `elasticloadbalancing:AddTags` Permission
- **Error**: `User is not authorized to perform: elasticloadbalancing:AddTags`
- **Solution**: Enhanced IAM policy with comprehensive tagging permissions
- **Implementation**: Policy now includes unrestricted AddTags for all ALB resources

#### Problem 2: Missing `elasticloadbalancing:DescribeListenerAttributes` Permission  
- **Error**: `User is not authorized to perform: elasticloadbalancing:DescribeListenerAttributes`
- **Solution**: Added comprehensive describe permissions for all ELB operations
- **Implementation**: 60+ describe permissions across EC2, ELB, Route53, EKS services

### 🚀 **Enhanced IAM Policy Features**

The updated `iam-policy.json` now includes:

```json
{
  "Comprehensive Describe Permissions": [
    "ec2:Describe* (25+ permissions)",
    "elasticloadbalancing:Describe* (10+ permissions)", 
    "route53:List* and route53:Get* permissions",
    "eks:Describe* and eks:List* permissions",
    "autoscaling:Describe* permissions",
    "logs:Describe* permissions",
    "iam:List* and iam:Get* permissions",
    "And many more..."
  ]
}
```

### 🔄 **Automatic Reconciliation Steps**

The script now includes automatic steps to handle permission updates:

1. **Force Ingress Reconciliation**: Updates ingress with new timestamp annotation
2. **Controller Restart**: Restarts ALB controller to pick up new IAM permissions  
3. **Status Verification**: Waits for controller restart completion
4. **Enhanced Logging**: Clear status messages for each step

### 📝 **Service Name Corrections**

- **Fixed**: Ingress backend service name from `api` to `omnixo-server`
- **Verified**: Both frontend (`omnixo-frontend:80`) and backend (`omnixo-server:3030`) routing
- **Tested**: ALB DNS resolution and traffic routing

### 🛠 **Troubleshooting Enhancements**

The script now provides:
- **Detailed error context** for IAM issues
- **Manual recovery commands** for common failures
- **Status checking commands** for debugging
- **Step-by-step verification** process

### ✅ **Validation Results**

After incorporating these fixes:
- ✅ ALB creates successfully without IAM errors
- ✅ Frontend accessible via ALB DNS
- ✅ Backend API routing configured (though may need service port adjustment)
- ✅ Comprehensive logging throughout setup process
- ✅ Automatic error recovery mechanisms

## Migration to IRSA (Optional)

For production environments, you can later migrate to IAM Roles for Service Accounts:
1. Set up OIDC provider
2. Create service account with IAM role annotation
3. Remove policy from worker node role
4. Update ALB controller to use new service account

This simplified approach gets you up and running quickly while maintaining the option to enhance security later.
