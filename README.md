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

3. **Kops Cluster Setup** (`4. Create a cluster using kops/`)
   - Kubernetes cluster creation using kops
   - Includes production environment setup
   - Note: Requires full AWS permissions (doesn't work in sandbox environments)

4. **EKS Pod Deployment** (`5. Deploy pods in cluster created by eksctl/`)
   - Create EKS cluster using eksctl
   - Deploy containerized frontend and backend applications
   - Kubernetes services and pod management
   - Port forwarding and testing strategies
   - Comprehensive guide for containerizing your own applications

## Prerequisites

1. Install [Terraform](https://developer.hashicorp.com/terraform/downloads)
2. Configure [AWS CLI](https://aws.amazon.com/cli/) with your credentials
3. Install [eksctl](https://eksctl.io/installation/) for EKS cluster management
4. Install [kubectl](https://kubernetes.io/docs/tasks/tools/) for Kubernetes operations
5. Basic understanding of AWS services (VPC, EC2, Security Groups)
6. Docker for containerizing applications

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
- EC2 instances are `t2.micro` (Free tier eligible) for basic exercises
- EKS clusters incur charges per hour - clean up when not in use
- Each exercise should be run with a fresh cluster to avoid configuration drift and conflicts

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

## Kops Cluster Setup

### ⚠️ Plot Twist: This Didn't Work! 

**TL;DR:** Tried to use kops in O'Reilly's AWS Sandbox. Turns out sandbox environments are called "sandbox" for a reason - they don't let you build castles (or Kubernetes clusters) in them! 🏰❌

**The Comedy of Errors:**
- kops: "Hey, can I create some VPCs?"
- AWS Sandbox: "Nope! 🙅‍♂️"
- kops: "How about some IAM roles?"
- AWS Sandbox: "Still nope! 🚫"
- kops: "Can I at least create a tiny EC2 instance?"
- AWS Sandbox: "Did I stutter? NOPE! 💀"

**What kops actually needs (and sandbox won't give):**
- VPC creation/modification (denied faster than a bad Tinder profile)
- EC2 instance management (sandbox said "not today, Satan")
- Auto Scaling Groups (apparently too dangerous for us mortals)
- Load Balancer creation (because load balancers are scary)
- IAM role creation (sandbox guards these like dragon treasure)
- Route53 DNS management (because DNS is apparently classified information)

**Lessons learned:**
1. Sandbox environments are great for learning... until they're not 😅
2. kops is like that friend who needs to borrow EVERYTHING to help you move
3. Always check IAM permissions before getting your hopes up

**What actually works in sandbox environments:**
- Crying softly 😢
- Learning to appreciate managed services like EKS
- Realizing why companies pay for real AWS accounts

### Prerequisites for Kops (If You Have Real AWS Access)
1. Install kops:
   ```bash
   brew install kops
   ```

2. Create an S3 bucket for state store:
   ```bash
   # Create the bucket (if your IAM gods smile upon you)
   aws s3api create-bucket \
       --bucket my-test-cluster-state-store \
       --region us-west-2 \
       --create-bucket-configuration LocationConstraint=us-west-2

   # Enable versioning (crossing fingers this works)
   aws s3api put-bucket-versioning \
       --bucket my-test-cluster-state-store \
       --versioning-configuration Status=Enabled
   ```

3. Set environment variables (assuming you made it this far without IAM errors):
   ```bash
   export KOPS_STATE_STORE=s3://my-test-cluster-state-store
   export KOPS_CLUSTER_NAME=my-test-cluster.k8s.local
   ```

### Deploy Kops Cluster (Theoretical Instructions)
**Disclaimer:** These steps are provided for educational purposes and nostalgia. They work great... if you're not in a sandbox! 🎭

1. Create the cluster configuration:
   ```bash
   kops create -f cluster.tmpl.yaml
   # 50/50 chance this will work in your environment
   ```

2. Create cluster secret:
   ```bash
   kops create secret --name ${KOPS_CLUSTER_NAME} sshpublickey admin -i ~/.ssh/id_rsa.pub
   # If this fails, blame the IAM permissions, not your SSH keys
   ```

3. Review the cluster configuration (this part usually works):
   ```bash
   kops get cluster
   kops get ig
   # At least you can see what WOULD have been created! 🤷‍♂️
   ```

4. Deploy the cluster (where dreams go to die):
   ```bash
   kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
   # *narrator voice*: "It was at this moment, they knew... they messed up"
   ```

5. Wait for the cluster to be ready (or wait for error messages):
   ```bash
   kops validate cluster --wait 10m
   # Spoiler alert: It won't validate in a sandbox 💔
   ```

6. Verify cluster (optimistic much?):
   ```bash
   kubectl get nodes
   # "No resources found" - the story of my kops life
   ```

### Delete Kops Cluster (The Only Command That Might Work)
To delete the cluster when you're done (or when it never worked in the first place):
```bash
kops delete cluster --name ${KOPS_CLUSTER_NAME} --yes
# Finally! A command that works in sandbox environments 🎉
# Because deleting nothing is apparently always allowed
```

**Pro Tip:** If you want to actually create a Kubernetes cluster in a restricted environment, stick with EKS using eksctl. It's like kops's more responsible sibling who actually gets invited to the AWS family dinner. 🍽️

## Contributing

Feel free to contribute by:
1. Forking the repository
2. Creating your feature branch
3. Committing your changes
4. Opening a pull request
