#!/bin/bash

# Function to list NAT gateways with their name tags if the state is not "deleted"
list_nat_gateways() {
    echo "Listing NAT gateways:"
    aws ec2 describe-nat-gateways --query 'NatGateways[?State != `deleted`].[NatGatewayId,Tags[?Key==`Name`].Value[]]' --output table
}

# Function to delete a NAT gateway and associated resources
delete_nat_gateway() {
    nat_gateway_id=$1
    
    # Get association ID of the NAT gateway
    association_id=$(aws ec2 describe-nat-gateways --nat-gateway-id "$nat_gateway_id" --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' --output text)

    # Get the route table ID associated with the NAT gateway
    route_table_id=$(aws ec2 describe-route-tables --query "RouteTables[?Associations[].RouteTableId | contains(@, '$nat_gateway_id')].RouteTableId" --output text)

    # Disassociate the route table from the NAT gateway
    if [ -n "$route_table_id" ]; then
        aws ec2 disassociate-route-table --association-id "$association_id"
    fi

    # Delete the route table
    if [ -n "$route_table_id" ]; then
        aws ec2 delete-route-table --route-table-id "$route_table_id"
    fi

    # Release the elastic IP address associated with the NAT gateway
    aws ec2 release-address --allocation-id "$association_id"

    # Delete the NAT gateway
    aws ec2 delete-nat-gateway --nat-gateway-id "$nat_gateway_id"

    echo "NAT gateway with ID $nat_gateway_id and associated resources deleted successfully."
}

# Main function
main() {
    while true; do
        # List NAT gateways
        list_nat_gateways

        # Prompt user to select a NAT gateway by name tag
        read -p "Enter the name tag of the NAT gateway you want to delete (or 'quit' to exit): " nat_name

        # Check if the user wants to quit
        if [ "$nat_name" == "quit" ]; then
            echo "Exiting."
            exit 0
        fi

        # Get the NAT gateway ID based on the provided name tag
        nat_gateway_id=$(aws ec2 describe-nat-gateways --query "NatGateways[?Tags[?Key=='Name' && Value=='$nat_name'] && State != 'deleted'].NatGatewayId" --output text)

        # Check if a NAT gateway with the provided name tag exists
        if [ -z "$nat_gateway_id" ]; then
            echo "Error: NAT gateway with name tag '$nat_name' not found or already deleted."
            continue
        fi

        # Confirm deletion
        read -p "Are you sure you want to delete NAT gateway '$nat_name'? This will also delete associated resources. (y/n): " confirm_delete
        if [ "$confirm_delete" == "y" ]; then
            # Delete NAT gateway and associated resources
            delete_nat_gateway "$nat_gateway_id"
            break
        else
            echo "Deletion cancelled."
        fi
    done
}

# Run the script
main
