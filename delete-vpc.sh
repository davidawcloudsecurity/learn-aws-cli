#!/bin/bash

# Retrieve all VPC IDs and their names/tags
vpcs=$(aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId, Tags[?Key==`Name`].Value | [0]]' --output text)

# Check if there are any VPCs
if [ -z "$vpcs" ]; then
  echo "No VPCs found."
  exit 1
fi

# Display the list of VPCs to the user
echo "Available VPCs:"
echo "$vpcs" | while read -r vpc_id vpc_name; do
  echo "VPC ID: $vpc_id, Name: ${vpc_name:-N/A}"
done

# Prompt the user to enter the VPC ID to delete
read -p "Enter the VPC ID you wish to delete: " vpc_id

# Confirm the VPC ID exists in the list
if ! echo "$vpcs" | grep -q "^$vpc_id"; then
  echo "Invalid VPC ID."
  exit 1
fi

delete_vpc() {
  echo "Attempting to delete VPC $vpc_id and its dependencies..."

  # Delete security groups (excluding the default security group)
  security_group_ids=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
  for sg_id in $security_group_ids; do
    aws ec2 delete-security-group --group-id $sg_id
    if [ $? -ne 0 ]; then
      echo "Failed to delete security group $sg_id"
    else
      echo "Deleted security group $sg_id"
    fi
  done

  # Delete network ACLs (excluding the default ACL)
  acl_ids=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$vpc_id" --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' --output text)
  for acl_id in $acl_ids; do
    aws ec2 delete-network-acl --network-acl-id $acl_id
    if [ $? -ne 0 ]; then
      echo "Failed to delete network ACL $acl_id"
    else
      echo "Deleted network ACL $acl_id"
    fi
  done

  # Delete subnets
  subnet_ids=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[*].SubnetId' --output text)
  for subnet_id in $subnet_ids; do
    aws ec2 delete-subnet --subnet-id $subnet_id
    if [ $? -ne 0 ]; then
      echo "Failed to delete subnet $subnet_id"
    else
      echo "Deleted subnet $subnet_id"
    fi
  done

  # Delete custom route tables (excluding the main route table)
  route_table_ids=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' --output text)
  for rtb_id in $route_table_ids; do
    aws ec2 delete-route-table --route-table-id $rtb_id
    if [ $? -ne 0 ]; then
      echo "Failed to delete route table $rtb_id"
    else
      echo "Deleted route table $rtb_id"
    fi
  done

  # Detach and delete the internet gateway
  igw_ids=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[*].InternetGatewayId' --output text)
  for igw_id in $igw_ids; do
    aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
    if [ $? -ne 0 ]; then
      echo "Failed to detach internet gateway $igw_id from VPC $vpc_id"
    else
      echo "Detached internet gateway $igw_id from VPC $vpc_id"
      aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
      if [ $? -ne 0 ]; then
        echo "Failed to delete internet gateway $igw_id"
      else
        echo "Deleted internet gateway $igw_id"
      fi
    fi
  done

  # Delete egress-only internet gateways (for dual stack VPC)
  eigw_ids=$(aws ec2 describe-egress-only-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'EgressOnlyInternetGateways[*].EgressOnlyInternetGatewayId' --output text)
  for eigw_id in $eigw_ids; do
    aws ec2 delete-egress-only-internet-gateway --egress-only-internet-gateway-id $eigw_id
    if [ $? -ne 0 ]; then
      echo "Failed to delete egress-only internet gateway $eigw_id"
    else
      echo "Deleted egress-only internet gateway $eigw_id"
    fi
  done

  # Disassociate and delete CIDR block associations
  cidr_association_ids=$(aws ec2 describe-vpcs --vpc-ids $vpc_id --query 'Vpcs[*].CidrBlockAssociationSet[*].AssociationId' --output text)
  for association_id in $cidr_association_ids; do
    aws ec2 disassociate-vpc-cidr-block --association-id $association_id
    if [ $? -ne 0 ]; then
      echo "Failed to disassociate CIDR block $association_id"
    else
      echo "Disassociated CIDR block $association_id"
    fi
  done

  # Delete DHCP options set
  dhcp_options_id=$(aws ec2 describe-vpcs --vpc-ids $vpc_id --query 'Vpcs[*].DhcpOptionsId' --output text)
  if [ "$dhcp_options_id" != "default" ]; then
    aws ec2 delete-dhcp-options --dhcp-options-id $dhcp_options_id
    if [ $? -ne 0 ]; then
      echo "Failed to delete DHCP options set $dhcp_options_id"
    else
      echo "Deleted DHCP options set $dhcp_options_id"
    fi
  fi

  # Finally, delete the VPC
  aws ec2 delete-vpc --vpc-id $vpc_id
  if [ $? -ne 0 ]; then
    echo "Failed to delete VPC $vpc_id"
  else
    echo "Deleted VPC $vpc_id"
  fi
}

while true; do
  delete_vpc
  if aws ec2 describe-vpcs --vpc-ids $vpc_id 2>/dev/null; then
    echo "VPC $vpc_id still exists, retrying..."
    sleep 5
  else
    echo "VPC $vpc_id and its dependencies have been successfully deleted."
    break
  fi
done
