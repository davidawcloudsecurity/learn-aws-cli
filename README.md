# learn-aws-cli
How to create, delete, list, users, password, groups and aws services

## Create the IAM user
```ruby
aws iam create-user --user-name <username>
aws iam create-login-profile --user-name <username> --password <password> --password-reset-required # remove to not require
aws iam add-user-to-group --user-name <username> --group-name <groupname>
```

