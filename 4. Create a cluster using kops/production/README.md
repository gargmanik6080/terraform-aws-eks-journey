# Production Cluster Configuration

This directory contains the complete YAML configurations for our production Kubernetes cluster.

## Files
- `cluster.yaml` - Main cluster configuration
- `instancegroups.yaml` - Node groups configuration

## How to Deploy

1. Set the state store:
```bash
export KOPS_STATE_STORE=s3://my-test-kops-state-store
```

2. Create the cluster:
```bash
kops create -f cluster.yaml
kops create -f instancegroups.yaml
```

3. Apply the configuration:
```bash
kops update cluster --yes
```

4. Validate the cluster:
```bash
kops validate cluster --wait 10m
```

## How to Delete

To delete the cluster:
```bash
kops delete cluster --name mycluster.myzone.com --yes
```
