#!/bin/bash

# Function to delete NAT gateway
delete_nat_gateway() {
    nat_gateway_id=$1

    aws ec2 delete-nat-gateway --nat-gateway-id "$nat_gateway_id"
    echo "NAT gateway with ID $nat_gateway_id deleted."
}

# Function to release associated Elastic IP
release_eip() {
    allocation_id=$1

    aws ec2 release-address --allocation-id "$allocation_id"
    echo "Elastic IP released."
}

# Function to check if NAT gateway is deleted
check_nat_gateway_deleted() {
    nat_gateway_id=$1

    state=$(aws ec2 describe-nat-gateways --nat-gateway-id "$nat_gateway_id" --query 'NatGateways[0].State' --output text)
    if [ "$state" == "deleted" ]; then
        return 0
    else
        return 1
    fi
}

# Function to remove route table associated with NAT gateway
remove_route_table_association() {
    nat_gateway_id=$1
    route_table_id=$(aws ec2 describe-route-tables --query "RouteTables[?Associations[].RouteTableId | contains(@, '$nat_gateway_id')].RouteTableId" --output text)

    if [ -n "$route_table_id" ]; then
        aws ec2 disassociate-route-table --association-id "$route_table_id"
        echo "Route table $route_table_id disassociated from NAT gateway."
    else
        echo "No route table associated with NAT gateway."
    fi
}

# Main function
main() {
    # Replace this with your NAT gateway ID
    nat_gateway_id="nat-0257fd94c9753f09d"

    # 1. Delete NAT gateway
    delete_nat_gateway "$nat_gateway_id"

    # 2. Wait for NAT gateway to be deleted
    while true; do
        check_nat_gateway_deleted "$nat_gateway_id"
        if [ $? -eq 0 ]; then
            break
        fi
        echo "NAT gateway is still deleting. Waiting for 5 seconds..."
        sleep 5
    done

    # 3. Release associated Elastic IP
    allocation_id=$(aws ec2 describe-nat-gateways --nat-gateway-id "$nat_gateway_id" --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' --output text)
    release_eip "$allocation_id"

    # 4. Remove route table association
    remove_route_table_association "$nat_gateway_id"
}

# Run the script
main
