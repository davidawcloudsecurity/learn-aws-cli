# AWS-CLI Cheatsheet
How to create, delete, list, users, password, groups and aws services

## Change profile
```ruby
export AWS_PROFILE=<user>
```

append or change profile under `~/.aws/credentials`

## To do chatgpt for this code
https://chat.openai.com/share/18db47c6-bf1f-4c6f-ab7d-ddc91b097fe6

## Resource

Official - https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-commandstructure.html

https://gist.github.com/davidmoremad/6db1981d37ed6b6481a29b91929a4fa4

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
## List IAM profile
```ruby
aws iam list-instance-profiles \
    --query 'InstanceProfiles[*].{ProfileName:InstanceProfileName,ProfileId:InstanceProfileId,Role:Roles[0].RoleName,Path:Path,CreateDate:CreateDate}' \
    --output table
```
## Create an instance to an existing VPC with public ip address
```ruby
ami_id=
subnet_id=
iam_profile=
aws ec2 run-instances \
    --image-id $ami_id \  # Replace with the actual RHEL AMI ID Default is ami-0fe630eb857a6ec83
    --instance-type t2.micro \  # Replace with your desired instance type
    --security-group-ids sg-01759b9859e9d8eee \  # Replace with your security group ID
    --subnet-id $subnet_id \  # Replace with your subnet ID
    --associate-public-ip-address \  # Enables public IP address
    --iam-instance-profile Name=$iam_profile \  # Replace with your IAM role name
    --user-data file://my-user-data.txt \  # Replace with the path to your user data file
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyRHELInstance}]'  # Replace with your desired tags
```
```ruby
Describe existing VPCs in a table
aws ec2 describe-vpcs \
    --query 'Vpcs[*].{VPC_ID:VpcId,CIDR_Block:CidrBlock,State:State,Tags:Tags}' \
    --output table

Describe existing VPCs & subnets in a table
aws ec2 describe-subnets \
    --query 'Subnets[*].{Subnet_ID:SubnetId,VPC_ID:VpcId,CIDR_Block:CidrBlock,AvailabilityZone:AvailabilityZone,State:State,Tags:Tags}' \
    --output table
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
