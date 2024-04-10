# learn-aws-cli
How to create, delete, list, users, password, groups and aws services

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
