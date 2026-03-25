#!/bin/bash
# Create a NAT Gateway in a public subnet with an Elastic IP
# Usage: ./create-nat-gw.sh <public-subnet-id> [name-tag]

set -e

SUBNET_ID="$1"
NAME="${2:-my-nat-gw}"

if [ -z "$SUBNET_ID" ]; then
    echo "Usage: ./create-nat-gw.sh <public-subnet-id> [name-tag]"
    echo "Example: ./create-nat-gw.sh subnet-xxx prod-nat"
    echo ""
    echo "Note: NAT Gateway MUST be in a public subnet"
    exit 1
fi

echo "Allocating Elastic IP for NAT..."
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
EIP_IP=$(aws ec2 describe-addresses --allocation-ids $EIP_ALLOC --query 'Addresses[0].PublicIp' --output text)
echo "  EIP: $EIP_IP ($EIP_ALLOC)"

echo "Creating NAT Gateway in subnet: $SUBNET_ID"

RESULT=$(aws ec2 create-nat-gateway \
    --subnet-id $SUBNET_ID \
    --allocation-id $EIP_ALLOC \
    --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=$NAME}]" \
    --output json)

NAT_GW_ID=$(echo $RESULT | jq -r '.NatGateway.NatGatewayId')

echo ""
echo "NAT Gateway creating... (takes 1-2 minutes)"
echo "  NAT GW ID: $NAT_GW_ID"
echo ""
echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

echo ""
echo "NAT Gateway is ready!"
echo "  NAT GW ID: $NAT_GW_ID"
echo "  Elastic IP: $EIP_IP"
echo "  Subnet: $SUBNET_ID"
