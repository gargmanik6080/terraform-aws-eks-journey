# Terraform AWS EKS Journey

A comprehensive Infrastructure as Code (IaC) learning path focusing on AWS EKS (Elastic Kubernetes Service) deployment and management. This project guides you from basic EC2 instances to production-ready Kubernetes clusters using both Terraform and eksctl approaches.

## 🎯 Project Overview

This repository contains a series of hands-on exercises that progressively build your skills in:

- AWS infrastructure provisioning with Terraform
- Kubernetes cluster setup and management
- Containerized application deployment
- Load balancer and ingress configuration
- IAM policy management for EKS

Each exercise builds upon knowledge from previous ones, creating a comprehensive learning path from basic cloud infrastructure to production-ready Kubernetes environments.

## 📚 Learning Path

### 1. [Basic EC2 Provisioning](./1.%20Provision%20an%20EC2/)
- Simple EC2 instance creation in existing subnet
- Basic AWS provider configuration
- Terraform state management introduction
- **Key Skills**: Terraform basics, EC2 provisioning

### 2. [VPC with EC2](./2.%20Provision%20VPC,Subnet%20and%20SGs%20with%20EC2/)
- Complete VPC setup with custom subnet
- Security Group configuration
- EC2 instance in the custom VPC
- **Key Skills**: VPC architecture, security groups, network ACLs

### 3. [Kops Cluster Setup](./4.%20Create%20a%20cluster%20using%20kops/)
- Kubernetes cluster creation using kops
- Production environment setup
- **Key Skills**: kops, Kubernetes basics, DNS configuration
- **Note**: Requires full AWS permissions (doesn't work in sandbox environments)

### 4. [EKS Pod Deployment](./5.%20Deploy%20pods%20in%20cluster%20created%20by%20eksctl/)
- EKS cluster creation using eksctl
- Deployment of containerized applications
- Kubernetes services and pod management
- Port forwarding and testing strategies
- **Key Skills**: eksctl, kubectl, container deployment, service configuration

### 5. [EKS with Load Balancer](./6.%20Deploy%20pods%20in%20cluster%20created%20by%20eksctl%20pt%202/COMBINED-README.md)
- AWS Load Balancer Controller setup
- ALB ingress configuration
- Production-ready external access
- IAM policy management
- **Key Skills**: ALB configuration, ingress resources, IAM policies, API routing

## 🛠️ Prerequisites

### Required Tools
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.0.0+)
- [AWS CLI](https://aws.amazon.com/cli/) (v2.0.0+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (v1.20.0+)
- [eksctl](https://eksctl.io/installation/) (v0.80.0+)
- [helm](https://helm.sh/docs/intro/install/) (v3.0.0+) - for AWS Load Balancer Controller
- [Docker](https://docs.docker.com/get-docker/) - for containerizing applications

### AWS Setup
1. AWS Account with appropriate permissions
2. AWS CLI configured with access keys:
   ```bash
   aws configure
   ```
3. Ensure quotas for EKS, EC2, and other services are sufficient
## 🚀 Getting Started

### Clone the Repository
```bash
git clone https://github.com/yourusername/terraform-journey-for-beginners.git
cd terraform-journey-for-beginners
```

### Follow Each Exercise in Sequence
1. Start with "1. Provision an EC2" and progress through each numbered directory
2. Read the README in each exercise directory before starting
3. Follow the step-by-step instructions in each exercise
4. Complete the exercises in order, as they build upon each other

## 📋 Usage Instructions

### Terraform Workflow (for Exercise 1 & 2)
```bash
# Initialize Terraform
cd "1. Provision an EC2"
terraform init

# Plan the infrastructure
terraform plan

# Apply the changes
terraform apply

# When finished, destroy resources
terraform destroy
```

### EKS Cluster Creation (for Exercise 4 & 5)
```bash
# Create EKS cluster
eksctl create cluster \
  --name my-eks-cluster \
  --region us-west-2 \
  --nodegroup-name my-nodes \
  --node-type t3.medium \
  --nodes 3

# Verify cluster creation
kubectl get nodes
```

### Automated Setup Scripts
Each exercise includes setup scripts to automate the deployment process:

```bash
cd "6. Deploy pods in cluster created by eksctl pt 2"
chmod +x setup-new.sh
./setup-new.sh
```

## 🔑 Key Concepts Covered

### Terraform
- Infrastructure as Code (IaC) fundamentals
- Resource declarations and dependencies
- State management
- Variable and output management

### AWS Services
- EC2 instances and AMIs
- VPC, subnets, and security groups
- IAM roles and policies
- EKS (Elastic Kubernetes Service)
- Application Load Balancers (ALB)

### Kubernetes
- Cluster architecture and components
- Pod deployment and lifecycle
- Service types and networking
- Ingress controllers and resources
- ConfigMaps and Secrets

### DevOps Practices
- Infrastructure automation
- Container orchestration
- Load balancing and traffic management
- IAM and security best practices

## 💡 Best Practices & Lessons Learned

### Infrastructure Management
- **State Management**: Keep Terraform state files secure and use remote backends in production
- **Resource Naming**: Use consistent naming conventions for all resources
- **Modularization**: Break complex infrastructure into reusable modules

### Kubernetes Operations
- **Right-sizing**: Choose appropriate instance types for node groups
- **IAM Permissions**: Follow least privilege principles for service accounts
- **Monitoring**: Implement logging and monitoring from the start

### Cost Optimization
- **Resource Cleanup**: Always destroy test resources when not in use
- **Spot Instances**: Consider spot instances for non-critical workloads
- **Autoscaling**: Implement autoscaling to match resource usage with demand

### Security
- **Network Isolation**: Use private subnets for worker nodes when possible
- **Security Groups**: Restrict inbound/outbound traffic to minimum required
- **IAM Roles**: Use fine-grained permissions with service account roles
## ⚠️ Cost Considerations

| Resource | Approximate Cost (US regions) |
|----------|-------------------------------|
| EC2 t3.medium | $0.0416/hour (~$30/month) |
| EKS Cluster | $0.10/hour (~$73/month) |
| Application Load Balancer | ~$22.50/month + data processing |
| NAT Gateway | ~$32/month + data processing |
| Data Transfer | $0.09/GB (outbound) |

**Always remember to clean up resources after completing exercises to avoid unexpected charges!**

## 🧹 Cleanup Instructions

### Terraform Resources
```bash
cd "directory_name"
terraform destroy -auto-approve
```

### EKS Cluster
```bash
eksctl delete cluster --name my-eks-cluster --region us-west-2
```

### Load Balancer and IAM Policy
```bash
# Delete ingress first (removes ALB)
kubectl delete ingress frontend-ingress

# Delete IAM policy
aws iam delete-policy --policy-arn arn:aws:iam::YOUR-ACCOUNT-ID:policy/AWSLoadBalancerControllerIAMPolicy
```
```

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [Terraform Documentation](https://www.terraform.io/docs)
- [eksctl Documentation](https://eksctl.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Happy learning! 🚀
4. Opening a pull request
