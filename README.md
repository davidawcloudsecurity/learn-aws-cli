# AWS-CLI Cheatsheet
How to create, delete, list, users, password, groups and aws services

Resource - https://gist.github.com/davidmoremad/6db1981d37ed6b6481a29b91929a4fa4

## Clean the \r from chatgpt
```ruby
sed -i 's/\r$//' filename
```

## Install aws cli
```ruby
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip; sudo ./aws/install;
sudo rm -rf awscliv2.zip
```
## Create the IAM user
```ruby
aws iam create-user --user-name <username>
aws iam create-login-profile --user-name <username> --password <password> --password-reset-required # remove to not require
aws iam add-user-to-group --user-name <username> --group-name <groupname>
```
## Bash script
```ruby
#!/bin/bash

# Prompt the user for input
read -p "Enter the username for the new IAM user: " username
read -sp "Enter the password for the new IAM user: " password
echo # Print a newline after the password prompt for better formatting
read -p "Enter the group name to add the user to: " groupname

# Create the IAM user
aws iam create-user --user-name "$username"

# Set the password for the IAM user
aws iam create-login-profile --user-name "$username" --password "$password" --password-reset-required

# Add the IAM user to the group
aws iam add-user-to-group --user-name "$username" --group-name "$groupname"

echo "IAM user '$username' has been created and added to the group '$groupname'."
```
## List NATs
```ruby
aws ec2 describe-nat-gateways
aws ec2 delete-nat-gateway --nat-gateway-id <nat-gateway-id>
```
## List VPCs and subnets
```ruby
aws ec2 describe-vpcs
aws ec2 describe-subnets

# List VPCs with a specific name tag
aws ec2 describe-vpcs --filters Name=tag:Name,Values=my-vpc

# List subnets in a specific VPC
aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-12345678
```
