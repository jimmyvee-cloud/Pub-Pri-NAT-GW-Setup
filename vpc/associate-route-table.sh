#!/bin/bash
# Associate a route table with a subnet
# Usage: ./associate-route-table.sh <route-table-id> <subnet-id>

set -e

RTB_ID="$1"
SUBNET_ID="$2"

if [ -z "$RTB_ID" ] || [ -z "$SUBNET_ID" ]; then
    echo "Usage: ./associate-route-table.sh <route-table-id> <subnet-id>"
    echo "Example: ./associate-route-table.sh rtb-xxx subnet-xxx"
    exit 1
fi

echo "Associating route table with subnet..."
echo "  Route Table: $RTB_ID"
echo "  Subnet: $SUBNET_ID"

RESULT=$(aws ec2 associate-route-table \
    --route-table-id $RTB_ID \
    --subnet-id $SUBNET_ID \
    --output json)

ASSOC_ID=$(echo $RESULT | jq -r '.AssociationId')

echo ""
echo "Association created!"
echo "  Association ID: $ASSOC_ID"
