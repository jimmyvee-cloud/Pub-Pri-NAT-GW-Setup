#!/bin/bash
# Add a route to a route table
# Usage: ./add-route.sh <route-table-id> <destination-cidr> <target-id>

set -e

RTB_ID="$1"
DEST_CIDR="$2"
TARGET_ID="$3"

if [ -z "$RTB_ID" ] || [ -z "$DEST_CIDR" ] || [ -z "$TARGET_ID" ]; then
    echo "Usage: ./add-route.sh <route-table-id> <destination-cidr> <target-id>"
    echo ""
    echo "Examples:"
    echo "  ./add-route.sh rtb-xxx 0.0.0.0/0 igw-xxx     # Internet via IGW"
    echo "  ./add-route.sh rtb-xxx 0.0.0.0/0 nat-xxx      # Outbound via NAT"
    echo "  ./add-route.sh rtb-xxx 10.1.0.0/16 pcx-xxx    # VPC peering"
    exit 1
fi

echo "Adding route..."
echo "  Route Table: $RTB_ID"
echo "  Destination: $DEST_CIDR"
echo "  Target: $TARGET_ID"

# Detect target type from prefix
if [[ "$TARGET_ID" == igw-* ]]; then
    aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block $DEST_CIDR --gateway-id $TARGET_ID
elif [[ "$TARGET_ID" == nat-* ]]; then
    aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block $DEST_CIDR --nat-gateway-id $TARGET_ID
elif [[ "$TARGET_ID" == pcx-* ]]; then
    aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block $DEST_CIDR --vpc-peering-connection-id $TARGET_ID
elif [[ "$TARGET_ID" == vgw-* ]]; then
    aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block $DEST_CIDR --gateway-id $TARGET_ID
elif [[ "$TARGET_ID" == tgw-* ]]; then
    aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block $DEST_CIDR --transit-gateway-id $TARGET_ID
else
    echo "Error: Unrecognized target type. Must start with igw-, nat-, pcx-, vgw-, or tgw-"
    exit 1
fi

echo ""
echo "Route added successfully!"
