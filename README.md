# Terraform AWS EKS Journey

Infrastructure as Code journey with Terraform, focusing on AWS EKS (Elastic Kubernetes Service) deployment and management. From basic EC2 instances to production-ready Kubernetes clusters using Terraform and eksctl approaches.

## Project Structure

1. **Basic EC2 Provisioning** (`1. Provision an EC2/`)
   - Simple EC2 instance creation in an existing subnet
   - Basic AWS provider configuration

2. **VPC with EC2** (`2. Provision VPC,Subnet and SGs with EC2/`)
   - Complete VPC setup with custom subnet
   - Security Group configuration
   - EC2 instance in the custom VPC

3. **EKS Cluster** (`3. Basic EKS Cluster/`)
   - Simple EKS cluster setup using eksctl
   - Basic node group configuration
   - Foundation for future Kubernetes deployments

## Prerequisites

1. Install [Terraform](https://developer.hashicorp.com/terraform/downloads)
2. Configure [AWS CLI](https://aws.amazon.com/cli/) with your credentials
3. Basic understanding of AWS services (VPC, EC2, Security Groups)

## Usage Instructions

### Initialize Terraform (for each project directory)
```bash
cd "directory_name"
terraform init
```

### Plan Your Infrastructure
```bash
terraform plan
```

### Apply Changes
```bash
terraform apply
```
When prompted, type `yes` to confirm the changes.

### Destroy Infrastructure
```bash
terraform destroy
```
When prompted, type `yes` to confirm the destruction of resources.

## Important Notes

- Always review the plan before applying changes
- Remember to destroy resources when done to avoid unnecessary charges
- The configurations use `us-west-2` (Oregon) region by default
- All instances are `t2.micro` (Free tier eligible)

## Security Considerations

- The security group in the VPC example needs to be configured with proper ingress/egress rules
- Always follow the principle of least privilege when configuring security groups
- Keep your AWS credentials secure and never commit them to the repository

## EKS Cluster Setup

### Prerequisites for EKS
1. Install eksctl:
   ```bash
   # For macOS with Homebrew
   brew install eksctl
   ```

2. Install kubectl:
   ```bash
   # For macOS with Homebrew
   brew install kubectl
   ```

3. Verify installations:
   ```bash
   eksctl version
   kubectl version --client
   ```

### Create Basic EKS Cluster
1. Create a basic cluster (this may take 15-20 minutes):
   ```bash
   eksctl create cluster \
     --name my-eks-cluster \
     --region us-west-2 \
     --nodegroup-name my-nodes \
     --node-type t3.medium \     # You can also use t2.medium. Note: m3.medium is deprecated
     --nodes 2 \
     --nodes-min 1 \
     --nodes-max 3
   ```

   **Note about instance types:**
   - `t3.medium` is recommended (newer, better performance)
   - `t2.medium` is a viable alternative
   - Avoid `m3` instances as they are older generation
   - Each node needs at least 2 vCPUs and 4GB RAM for Kubernetes components

2. Verify cluster creation:
   ```bash
   kubectl get nodes
   ```

### Delete EKS Cluster
When you're done experimenting, delete the cluster to avoid charges:
```bash
eksctl delete cluster --name my-eks-cluster --region us-west-2
```

## Contributing

Feel free to contribute by:
1. Forking the repository
2. Creating your feature branch
3. Committing your changes
4. Opening a pull request
