#!/bin/bash
# Create a route table and associate it with a subnet
# Usage: ./create-route-table.sh <vpc-id> <name-tag>

set -e

VPC_ID="$1"
NAME="$2"

if [ -z "$VPC_ID" ] || [ -z "$NAME" ]; then
    echo "Usage: ./create-route-table.sh <vpc-id> <name-tag>"
    echo "Example: ./create-route-table.sh vpc-xxx public-rt"
    exit 1
fi

echo "Creating route table..."
echo "  VPC: $VPC_ID"
echo "  Name: $NAME"

RESULT=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$NAME}]" \
    --output json)

RTB_ID=$(echo $RESULT | jq -r '.RouteTable.RouteTableId')

echo ""
echo "Route table created!"
echo "  Route Table ID: $RTB_ID"
echo ""
echo "Next: add routes and associate with a subnet"
echo "  ./add-route.sh $RTB_ID 0.0.0.0/0 <igw-id|nat-id>"
echo "  ./associate-route-table.sh $RTB_ID <subnet-id>"
