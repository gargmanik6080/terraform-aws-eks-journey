# Exercise 5: Deploy Pods in Cluster Created by eksctl

This exercise demonstrates how to create an Amazon EKS cluster using eksctl and deploy a containerized application with frontend and backend components.

## Overview

In this exercise, you will:
1. Create an EKS cluster using eksctl
2. Deploy frontend and backend pods
3. Create services to expose the applications
4. Test the deployment using port forwarding

## Prerequisites

- AWS CLI configured with appropriate credentials
- eksctl installed
- kubectl installed
- Docker images available in Docker Hub:
  - `gargmanik6080/client:latest` (frontend)
  - `gargmanik6080/server:latest` (backend)

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Frontend Pod  │    │   Backend Pod   │
│                 │    │                 │
│ gargmanik6080/  │    │ gargmanik6080/  │
│ client:latest   │    │ server:latest   │
│ Port: 80        │    │ Port: 80        │
└─────────────────┘    └─────────────────┘
         │                       │
         │                       │
┌─────────────────┐    ┌─────────────────┐
│ omnixo-frontend │    │ omnixo-server   │
│ Service         │    │ Service         │
│ Port: 8080→80   │    │ Port: 3030→80   │
│ Type: ClusterIP │    │ Type: ClusterIP │
└─────────────────┘    └─────────────────┘
```

## Files Description

### Infrastructure Files
- **setup.sh**: Script to create EKS cluster and deploy all resources
- **frontend.yaml**: Pod definition for the frontend application
- **backend.yaml**: Pod definition for the backend application
- **svc-frontend.yml**: Service definition for frontend
- **svc-backend.yaml**: Service definition for backend

## Step-by-Step Guide

### 1. Configure AWS CLI
```bash
aws configure
```
Enter your AWS credentials when prompted.

### 2. Create EKS Cluster
```bash
eksctl create cluster \
  --name my-test-cluster \
  --region us-west-2 \
  --nodes 5 \
  --node-type m3.medium \
  --managed
```

**Parameters explained:**
- `--name`: Name of the EKS cluster
- `--region`: AWS region to deploy the cluster
- `--nodes`: Number of worker nodes
- `--node-type`: EC2 instance type for worker nodes
- `--managed`: Use managed node groups

### 3. Deploy Application Resources
```bash
# Deploy pods
kubectl apply -f frontend.yaml
kubectl apply -f backend.yaml

# Deploy services
kubectl apply -f svc-frontend.yaml
kubectl apply -f svc-backend.yaml
```

### 4. Verify Deployment
```bash
# Check pods status
kubectl get pods

# Check services
kubectl get services

# Get detailed information
kubectl describe pod frontend
kubectl describe pod backend
```

## Testing the Deployment

At this point, both the frontend and backend are individually accessible through multiple methods:

### 1. Port Forward to Access Applications
```bash
# Access frontend locally
kubectl port-forward service/omnixo-frontend 8080:8080
# Access the frontend at: http://localhost:8080

# Access backend locally (in a new terminal)
kubectl port-forward service/omnixo-server 3030:3030
# Access the backend at: http://localhost:3030
```

### 2. Test with Curl Pod
```bash
kubectl run curlpod -it --rm --image=curlimages/curl:latest -- /bin/sh
```

Inside the curl pod, test connectivity:
```bash
# Test frontend service
curl omnixo-frontend:8080

# Test backend service
curl omnixo-server:3030
curl omnixo-server:80
```

## Containerizing Your Own Application

While this exercise uses pre-built Docker images (`gargmanik6080/client:latest` and `gargmanik6080/server:latest`), I **highly recommend** containerizing a simple web application yourself to gain deeper understanding.

### Why Containerize Your Own App?

Containerizing your own application helps answer critical questions that you'll encounter in real-world scenarios:

1. **Which port should I use inside the container?**
2. **What does the `EXPOSE` directive actually do?**
3. **Does `EXPOSE` actually expose the container port on the host machine?**
4. **How do I handle environment variables and configuration?**
5. **What base image should I choose for optimal size and security?**
6. **What is the difference between args and env in Dockerfile?**
7. **What is the difference between -p and -P flags in Docker?**


### Example: OmniXO Tic-Tac-Toe Application

For this exercise, I containerized my **OmniXO** application - a full-stack Tic-Tac-Toe game with:
- **Frontend**: React with Vite (served on port 80 in container)
- **Backend**: Flask API (served on port 80 in container)

You can find the complete source code at: [OmniXO Repository](https://github.com/gargmanik6080/OmniXO)

### Key Docker Concepts Learned

### Hands-On Exercise: Containerize OmniXO

1. **Clone the repository:**
   ```bash
   git clone https://github.com/gargmanik6080/OmniXO.git
   cd OmniXO
   ```

2. **Build the backend:**
   ```bash
   cd server
   docker build -t your-username/omnixo-server:latest .
   ```

3. **Build the frontend:**
   ```bash
   cd ../client
   docker build -t your-username/omnixo-client:latest .
   ```

4. **Test locally:**
   ```bash
   # Run backend
   docker run -d -p 3030:80 --name backend your-username/omnixo-server:latest
   
   # Run frontend
   docker run -d -p 8080:80 --name frontend your-username/omnixo-client:latest
   ```

5. **Push to Docker Hub:**
   ```bash
   docker push your-username/omnixo-server:latest
   docker push your-username/omnixo-client:latest
   ```

6. **Update the Kubernetes YAML files** to use your images instead of `gargmanik6080/*`

## Scaling Options (Optional)

### Add Additional Node Group
```bash
eksctl create nodegroup \
  --cluster my-test-cluster \
  --name large-ng \
  --node-type m3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3
```

## Cleanup

### Delete Resources
```bash
# Delete services
kubectl delete service omnixo-frontend omnixo-server

# Delete pods
kubectl delete pod frontend backend

# Delete cluster
eksctl delete cluster --name my-test-cluster --region us-west-2
```

## Key Concepts Learned

1. **eksctl**: Simplified tool for creating and managing EKS clusters
2. **Kubernetes Pods**: Basic execution units that can contain one or more containers
3. **Kubernetes Services**: Abstract way to expose applications running on pods
4. **ClusterIP**: Internal service type for communication within the cluster
5. **Port Forwarding**: Method to access cluster services from local machine
6. **Labels and Selectors**: Mechanism to link services to pods

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**
   ```bash
   kubectl describe pod <pod-name>
   ```
   Check for resource constraints or node availability.

2. **Service not accessible**
   ```bash
   kubectl get endpoints
   ```
   Verify that service selectors match pod labels.

3. **Image pull errors**
   ```bash
   kubectl logs <pod-name>
   ```
   Check if Docker images are publicly accessible.

### Useful Commands
```bash
# View cluster info
kubectl cluster-info

# Get all resources
kubectl get all

# View logs
kubectl logs <pod-name>

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/sh

# Describe any resource
kubectl describe <resource-type> <resource-name>
```

## Next Steps

After completing this exercise, you can:
- Explore Kubernetes Deployments for better pod management
- Learn about ConfigMaps and Secrets for configuration management
- Implement Ingress controllers for external access
- Set up monitoring and logging solutions
- Practice with Helm charts for package management

**Note:** The next exercise will build upon this same EKS cluster setup, so you may want to keep your cluster running if you plan to continue with the subsequent directory immediately.

## Cost Considerations

- EKS cluster incurs charges per hour
- Worker nodes (EC2 instances) are charged based on instance type
- Always clean up resources when not in use
- Consider using spot instances for cost optimization in non-production environments
