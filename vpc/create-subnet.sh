#!/bin/bash
# Create a subnet in a VPC
# Usage: ./create-subnet.sh <vpc-id> <cidr-block> <az> <name-tag> [--public]

set -e

VPC_ID="$1"
CIDR="$2"
AZ="$3"
NAME="$4"
PUBLIC="$5"

if [ -z "$VPC_ID" ] || [ -z "$CIDR" ] || [ -z "$AZ" ] || [ -z "$NAME" ]; then
    echo "Usage: ./create-subnet.sh <vpc-id> <cidr-block> <az> <name-tag> [--public]"
    echo ""
    echo "Examples:"
    echo "  ./create-subnet.sh vpc-xxx 10.0.1.0/24 eu-west-2a public-subnet --public"
    echo "  ./create-subnet.sh vpc-xxx 10.0.2.0/24 eu-west-2a private-subnet"
    echo ""
    echo "  --public  enables auto-assign public IPv4"
    exit 1
fi

echo "Creating subnet..."
echo "  VPC: $VPC_ID"
echo "  CIDR: $CIDR"
echo "  AZ: $AZ"
echo "  Name: $NAME"

RESULT=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $CIDR \
    --availability-zone $AZ \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$NAME}]" \
    --output json)

SUBNET_ID=$(echo $RESULT | jq -r '.Subnet.SubnetId')

# Enable auto-assign public IP if --public
if [ "$PUBLIC" = "--public" ]; then
    aws ec2 modify-subnet-attribute \
        --subnet-id $SUBNET_ID \
        --map-public-ip-on-launch
    echo "  Auto-assign public IP: enabled"
fi

echo ""
echo "Subnet created successfully!"
echo "  Subnet ID: $SUBNET_ID"
