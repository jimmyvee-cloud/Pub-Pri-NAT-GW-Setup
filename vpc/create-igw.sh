#!/bin/bash
# Create and attach an Internet Gateway to a VPC
# Usage: ./create-igw.sh <vpc-id> [name-tag]

set -e

VPC_ID="$1"
NAME="${2:-my-igw}"

if [ -z "$VPC_ID" ]; then
    echo "Usage: ./create-igw.sh <vpc-id> [name-tag]"
    echo "Example: ./create-igw.sh vpc-xxx prod-igw"
    exit 1
fi

echo "Creating Internet Gateway..."

RESULT=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$NAME}]" \
    --output json)

IGW_ID=$(echo $RESULT | jq -r '.InternetGateway.InternetGatewayId')

echo "Attaching to VPC: $VPC_ID"
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

echo ""
echo "Internet Gateway created and attached!"
echo "  IGW ID: $IGW_ID"
echo "  VPC: $VPC_ID"
