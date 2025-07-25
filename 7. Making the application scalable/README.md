# Exercise 7: Making the Application Scalable

This exercise demonstrates how to make your Kubernetes application more scalable and resilient by implementing deployment strategies, horizontal scaling, and proper cluster configuration.

## Overview

In this exercise, we upgrade our application from individual pods to deployments with multiple replicas. This approach provides better resilience, scalability, and easier management compared to manually creating and managing individual pods.

## Key Improvements from Previous Exercise

1. **Kubernetes Deployments**: Using deployment objects instead of individual pods
2. **Horizontal Pod Scaling**: Running multiple replicas of each application component
3. **Declarative Cluster Configuration**: Using YAML-based `eksctl` configuration instead of CLI parameters
4. **Bottlerocket AMI**: Using AWS's container-optimized AMI for better security and performance
5. **Enhanced Monitoring**: CloudWatch integration for comprehensive cluster logging

## Files in this Directory

- `cluster-conf.yaml`: Declarative EKS cluster configuration
- `backend-deploy.yaml`: Backend API deployment with multiple replicas
- `frontend-deploy.yaml`: Frontend application deployment with multiple replicas
- `svc-backend.yaml`: Service definition for backend API
- `svc-frontend.yaml`: Service definition for frontend application
- `frontend-ingress.yaml`: ALB ingress configuration
- `setup.sh`: Automated setup script for deploying the entire infrastructure
- `iam-policy.json`: IAM policy for AWS Load Balancer Controller

## Key Features

### 1. Deployment Objects

Unlike pods that run as individual instances, deployments manage multiple replicas of a pod template, providing:
- Self-healing capabilities (automatically replaces failed pods)
- Scaling capabilities (easily scale up/down the number of replicas)
- Rolling update support (zero-downtime deployments)

### 2. Declarative Cluster Configuration

The `cluster-conf.yaml` file provides a declarative way to create and manage EKS clusters, including:
- Node group definitions with instance types and scaling parameters
- Bottlerocket AMI for improved security and performance
- IAM policies for AWS integrations (AutoScaler, ALB Ingress, etc.)
- CloudWatch integration for logging

### 3. Auto-Scaling Support

The node group is configured with policies that enable:
- Kubernetes Cluster Autoscaler compatibility
- AWS ALB Ingress Controller support
- CloudWatch monitoring

## Getting Started

1. Review the `cluster-conf.yaml` file to understand the cluster configuration
2. Examine the deployment YAML files to understand how multiple replicas are configured
3. Run the setup script to deploy the infrastructure:

```bash
./setup.sh
```

## Resources

- [Kubernetes Deployments Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [eksctl Configuration Schema](https://eksctl.io/usage/schema/)
- [AWS Bottlerocket Documentation](https://aws.amazon.com/bottlerocket/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
