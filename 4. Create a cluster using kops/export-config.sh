#!/bin/zsh

# Set your cluster name
CLUSTER_NAME="mycluster.myzone.com"

# Set state store if not already set
if [ -z "$KOPS_STATE_STORE" ]; then
    export KOPS_STATE_STORE=s3://my-test-kops-state-store
fi

# Create production directory if it doesn't exist
mkdir -p production

# Export cluster configuration
echo "Exporting cluster configuration..."
kops get cluster $CLUSTER_NAME -o yaml > production/cluster.yaml

# Export instance groups
echo "Exporting instance groups..."
kops get ig -o yaml > production/instancegroups.yaml

echo "Configuration exported to production/ directory"
echo "You can now use these files to recreate the cluster in the future"
