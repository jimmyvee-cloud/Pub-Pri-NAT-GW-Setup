#!/bin/bash
# Create a VPC
# Usage: ./create-vpc.sh <cidr-block> [name-tag]

set -e

CIDR="$1"
NAME="${2:-my-vpc}"

if [ -z "$CIDR" ]; then
    echo "Usage: ./create-vpc.sh <cidr-block> [name-tag]"
    echo ""
    echo "Examples:"
    echo "  ./create-vpc.sh 10.0.0.0/16 prod-vpc"
    echo "  ./create-vpc.sh 172.16.0.0/16 dev-vpc"
    exit 1
fi

echo "Creating VPC..."
echo "  CIDR: $CIDR"
echo "  Name: $NAME"

RESULT=$(aws ec2 create-vpc \
    --cidr-block $CIDR \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$NAME}]" \
    --output json)

VPC_ID=$(echo $RESULT | jq -r '.Vpc.VpcId')

# Enable DNS hostnames and DNS support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}'
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support '{"Value":true}'

echo ""
echo "VPC created successfully!"
echo "  VPC ID: $VPC_ID"
echo "  CIDR: $CIDR"
echo "  DNS Hostnames: enabled"
echo "  DNS Support: enabled"
