# Creating Kubernetes Cluster with kops

This guide documents the attempted process of creating a Kubernetes cluster using kops in AWS.

## ⚠️ Update: Unsuccessful Due to IAM Restrictions

**Note: This cluster creation was attempted but unsuccessful due to O'Reilly AWS Sandbox limitations.**

The O'Reilly AWS Sandbox environment has restricted IAM permissions that prevent kops from creating the necessary AWS resources. Kops requires extensive permissions including:
- VPC and subnet creation/modification
- EC2 instance management
- Auto Scaling Groups
- Load Balancer creation
- IAM role creation and management
- Route53 DNS management

These permissions are typically restricted in sandbox environments for security reasons.

**Alternative approaches for learning:**
- Use a personal AWS account with full permissions
- Try AWS EKS with eksctl (may have fewer permission requirements)
- Use local Kubernetes solutions like minikube or kind

## Important Note: kops vs EKS

**kops creates a self-managed Kubernetes cluster, NOT an EKS cluster.**

### Key Differences:
- **kops**: Self-managed cluster using EC2 instances - will NOT appear in EKS console
- **EKS**: AWS-managed Kubernetes service - appears in EKS console

### Where to see your kops cluster in AWS Console:
1. **EC2 Dashboard** → Instances (control plane, worker nodes, bastion)
2. **VPC Dashboard** → Your VPC, subnets, security groups
3. **Auto Scaling Groups** → Node group ASGs
4. **Load Balancers** → API server load balancer

If you want an EKS cluster instead, use:
```bash
# EKS cluster using eksctl (appears in EKS console)
eksctl create cluster --name my-eks-cluster --region us-west-2
```

## Prerequisites

1. Install kops:
   ```bash
   brew install kops
   ```

2. Configure AWS CLI with appropriate permissions
3. Create an S3 bucket for state store:
   ```bash
   aws s3api create-bucket \
       --bucket my-test-kops-state-store \
       --region us-west-2 \
       --create-bucket-configuration LocationConstraint=us-west-2

   aws s3api put-bucket-versioning \
       --bucket my-test-kops-state-store \
       --versioning-configuration Status=Enabled
   ```

## Cluster Creation

### Method 1: Create cluster with existing VPC
```bash
kops create cluster mycluster.myzone.com \
    --zones "us-west-2a,us-west-2b,us-west-2c" \
    --control-plane-zones "us-west-2a,us-west-2b,us-west-2c" \
    --networking calico \
    --topology private \
    --bastion \
    --node-count 3 \
    --node-size m3.medium \
    --kubernetes-version 1.27.1 \
    --control-plane-size t3.medium \
    --network-id vpc-YOUR_VPC_ID \
    --vpc vpc-YOUR_VPC_ID
```

Note: When using existing VPC, ensure:
- No CIDR conflicts with existing subnets
- Proper VPC configurations (DNS hostnames, DNS resolution enabled)
- Appropriate routing tables and internet gateway

### Method 2: Create cluster with new VPC (Recommended for testing)

1. **Create the cluster configuration:**
   ```bash
   kops create cluster mycluster.myzone.com \
       --zones "us-west-2a,us-west-2b,us-west-2c" \
       --control-plane-zones "us-west-2a,us-west-2b,us-west-2c" \
       --networking calico \
       --topology private \
       --bastion \
       --node-count 3 \
       --node-size m3.medium \
       --kubernetes-version 1.33.0 \
       --control-plane-size m3.medium
   ```

2. **Apply the cluster configuration:**
   ```bash
   kops update cluster --name mycluster.myzone.com --yes --admin
   ```

3. **Wait for cluster to be ready (10-15 minutes):**
   ```bash
   kops validate cluster --wait 15m
   ```

4. **Verify cluster is working:**
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## What Gets Created

### 1. State Store (S3 Bucket)
The cluster configuration is stored in your S3 bucket:
- Cluster specification
- Instance group definitions
- PKI certificates and keys
- Kubernetes manifests
- Node configuration files

### 2. AWS Resources (when you run `kops update cluster --yes`)
- VPC with public/private subnets
- EC2 instances (control plane, worker nodes, bastion)
- Auto Scaling Groups
- Load Balancers (for API server)
- Security Groups
- IAM roles and policies
- Route tables and NAT gateways

### 3. Local Files
- No files are created locally by default

To view the actual cluster configuration stored in S3:
```bash
# View cluster config
kops get cluster mycluster.myzone.com -o yaml

# View instance groups
kops get ig -o yaml

# List all objects in state store
aws s3 ls s3://my-test-kops-state-store/ --recursive
```

## Troubleshooting

### Common Issues

1. **Cluster Already Exists Error**
   ```
   Error: cluster "mycluster.myzone.com" already exists
   ```
   Solution:
   ```bash
   # Delete existing cluster
   kops delete cluster mycluster.myzone.com --yes
   ```

2. **Subnet CIDR Conflicts**
   ```
   error creating subnet: InvalidSubnet.Conflict: The CIDR conflicts with another subnet
   ```
   Solutions:
   - Use different CIDR ranges
   - Create cluster in new VPC (remove --network-id flag)

4. **State Store Issues**
   Always set KOPS_STATE_STORE before running commands:
   ```bash
   export KOPS_STATE_STORE=s3://my-test-kops-state-store
   ```

## Cluster Management

### Export Cluster Configuration
Save cluster configuration for future use:
```bash
kops get cluster mycluster.myzone.com -o yaml > cluster.yaml
```

### Update Cluster
```bash
kops update cluster mycluster.myzone.com --yes
```

### Validate Cluster
```bash
kops validate cluster --wait 10m
```

### Delete Cluster
```bash
kops delete cluster mycluster.myzone.com --yes
```

## Best Practices

1. Always use `--topology private` for production clusters
2. Use t3.medium or larger for node instances
3. Keep Kubernetes version up to date
4. Enable versioning on state store bucket
5. Regular backup of cluster configuration