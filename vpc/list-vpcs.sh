#!/bin/bash
# List all VPCs
# Usage: ./list-vpcs.sh

echo "VPCs:"
echo ""

aws ec2 describe-vpcs \
    --query 'Vpcs[*].{
        VpcId:VpcId,
        Name:Tags[?Key==`Name`]|[0].Value,
        CIDR:CidrBlock,
        State:State,
        IsDefault:IsDefault
    }' \
    --output table
