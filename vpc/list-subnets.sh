#!/bin/bash
# List subnets (optionally filter by VPC)
# Usage: ./list-subnets.sh [vpc-id]

VPC_ID="$1"

echo "Subnets:"
echo ""

if [ -n "$VPC_ID" ]; then
    aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'Subnets[*].{
            SubnetId:SubnetId,
            Name:Tags[?Key==`Name`]|[0].Value,
            CIDR:CidrBlock,
            AZ:AvailabilityZone,
            PublicIP:MapPublicIpOnLaunch,
            AvailableIPs:AvailableIpAddressCount,
            State:State
        }' \
        --output table
else
    aws ec2 describe-subnets \
        --query 'Subnets[*].{
            SubnetId:SubnetId,
            Name:Tags[?Key==`Name`]|[0].Value,
            VpcId:VpcId,
            CIDR:CidrBlock,
            AZ:AvailabilityZone,
            PublicIP:MapPublicIpOnLaunch,
            AvailableIPs:AvailableIpAddressCount
        }' \
        --output table
fi
