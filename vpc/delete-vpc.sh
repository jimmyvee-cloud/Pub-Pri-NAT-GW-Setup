#!/bin/bash
# Delete a VPC and its dependencies
# Usage: ./delete-vpc.sh <vpc-id> [--force]

set -e

VPC_ID="$1"
FORCE="$2"

if [ -z "$VPC_ID" ]; then
    echo "Usage: ./delete-vpc.sh <vpc-id> [--force]"
    echo "Example: ./delete-vpc.sh vpc-xxx"
    echo ""
    echo "Note: All resources inside the VPC must be deleted first."
    echo "      Use --force to auto-delete NAT GWs, IGW, subnets, route tables, etc."
    exit 1
fi

VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].Tags[?Key==`Name`].Value' --output text 2>/dev/null || echo "unnamed")
echo "VPC: $VPC_ID ($VPC_NAME)"

if [ "$FORCE" != "--force" ]; then
    read -p "Delete this VPC and all its resources? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

echo ""
echo "Cleaning up VPC resources..."

# Delete NAT Gateways
echo "  Deleting NAT Gateways..."
for NAT_ID in $(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query 'NatGateways[*].NatGatewayId' --output text); do
    echo "    Deleting: $NAT_ID"
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
done

# Wait for NAT GWs to delete
echo "  Waiting for NAT Gateways to delete..."
for NAT_ID in $(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=deleting" --query 'NatGateways[*].NatGatewayId' --output text); do
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_ID 2>/dev/null || sleep 30
done

# Detach and delete Internet Gateway
echo "  Detaching Internet Gateway..."
for IGW_ID in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].InternetGatewayId' --output text); do
    echo "    Detaching: $IGW_ID"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
    echo "    Deleting: $IGW_ID"
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
done

# Delete subnets
echo "  Deleting subnets..."
for SUBNET_ID in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text); do
    echo "    Deleting: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id $SUBNET_ID
done

# Delete custom route tables (not main)
echo "  Deleting route tables..."
for RTB_ID in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
    # Disassociate first
    for ASSOC_ID in $(aws ec2 describe-route-tables --route-table-ids $RTB_ID --query 'RouteTables[0].Associations[?!Main].RouteTableAssociationId' --output text); do
        aws ec2 disassociate-route-table --association-id $ASSOC_ID 2>/dev/null || true
    done
    echo "    Deleting: $RTB_ID"
    aws ec2 delete-route-table --route-table-id $RTB_ID
done

# Delete security groups (not default)
echo "  Deleting security groups..."
for SG_ID in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
    echo "    Deleting: $SG_ID"
    aws ec2 delete-security-group --group-id $SG_ID
done

# Release EIPs that were used by NAT gateways (unassociated ones)
echo "  Releasing orphaned Elastic IPs..."
for EIP_ALLOC in $(aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text); do
    echo "    Releasing: $EIP_ALLOC"
    aws ec2 release-address --allocation-id $EIP_ALLOC 2>/dev/null || true
done

# Delete VPC
echo ""
echo "Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID

echo ""
echo "VPC $VPC_ID deleted successfully!"
