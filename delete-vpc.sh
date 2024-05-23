#!/bin/bash

# Function to list VPCs and get user selection
select_vpc() {
    echo "Available VPCs:"
    VPC_IDS=$(aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value | [0],CidrBlock]' --output text)
    echo "$VPC_IDS" | nl
    read -p "Enter the number of the VPC you want to delete: " VPC_NUM
    VPC_ID=$(echo "$VPC_IDS" | sed -n "${VPC_NUM}p" | awk '{print $1}')
}

# Function to get IGW and EIGW IDs for the selected VPC
get_gateway_ids() {
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
    EIGW_ID=$(aws ec2 describe-egress-only-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'EgressOnlyInternetGateways[0].EgressOnlyInternetGatewayId' --output text)
    echo "Selected VPC: $VPC_ID"
    echo "Internet Gateway ID: $IGW_ID"
    echo "Egress-only Internet Gateway ID: $EIGW_ID"
}

# Function to delete security groups
delete_security_groups() {
    echo "Deleting security groups..."
    SG_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
    for SG_ID in $SG_IDS; do
        aws ec2 delete-security-group --group-id $SG_ID
    done
}

# Function to delete network ACLs
delete_network_acls() {
    echo "Deleting network ACLs..."
    ACL_IDS=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkAcls[?IsDefault==false].NetworkAclId" --output text)
    for ACL_ID in $ACL_IDS; do
        aws ec2 delete-network-acl --network-acl-id $ACL_ID
    done
}

# Function to delete subnets
delete_subnets() {
    echo "Deleting subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text)
    for SUBNET_ID in $SUBNET_IDS; do
        aws ec2 delete-subnet --subnet-id $SUBNET_ID
    done
}

# Function to delete route tables
delete_route_tables() {
    echo "Deleting route tables..."
    RTB_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?Associations[0].Main==false].RouteTableId" --output text)
    for RTB_ID in $RTB_IDS; do
        aws ec2 delete-route-table --route-table-id $RTB_ID
    done
}

# Function to detach and delete internet gateway
delete_internet_gateway() {
    echo "Detaching and deleting internet gateway..."
    if [ "$IGW_ID" != "None" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
    fi
}

# Function to delete egress-only internet gateway
delete_egress_only_internet_gateway() {
    echo "Deleting egress-only internet gateway..."
    if [ "$EIGW_ID" != "None" ]; then
        aws ec2 delete-egress-only-internet-gateway --egress-only-internet-gateway-id $EIGW_ID
    fi
}

# Function to delete the VPC
delete_vpc() {
    echo "Deleting VPC..."
    aws ec2 delete-vpc --vpc-id $VPC_ID
}

# Main script execution
select_vpc
get_gateway_ids
delete_security_groups
delete_network_acls
delete_subnets
delete_route_tables
delete_internet_gateway
delete_egress_only_internet_gateway
delete_vpc

echo "VPC and its resources have been successfully deleted."
