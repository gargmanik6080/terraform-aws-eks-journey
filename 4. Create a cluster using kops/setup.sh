#!/bin/bash

# Create unique bucket name with timestamp
# BUCKET_NAME="kops-state-$(date +%s)"
# echo "Creating S3 bucket: $BUCKET_NAME"
# export BUCKET_NAME=$BUCKET_NAME

# Create S3 bucket
# aws s3api create-bucket \
#     --bucket $BUCKET_NAME \
#     --region us-west-2 \
#     --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Set environment variable
export KOPS_STATE_STORE=s3://$BUCKET_NAME
echo "KOPS_STATE_STORE set to: $KOPS_STATE_STORE"
echo ""
echo "To use this bucket in future sessions, run:"
echo "export KOPS_STATE_STORE=s3://$BUCKET_NAME"

kops create cluster mycluster.myzone.com \
  --zones=us-west-2a,us-west-2b,us-west-2c \
  --control-plane-zones=us-west-2a,us-west-2b,us-west-2c \
  --networking=calico \
  --topology=private \
  --bastion \
  --node-count=3 \
  --node-size=t3.micro \
  --control-plane-size=t3.micro \
  --instance-manager=cloudgroups


kops update cluster --name mycluster.myzone.com --yes --admin