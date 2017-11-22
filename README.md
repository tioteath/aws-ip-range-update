AWS Lambda function to request AWS IP ranges from https://ip-ranges.amazonaws.com
for the REGION and update security groups from the SECURITY_GROUP
with IP range of the SECURITY_GROUP_LIMIT length.

Environment:

Name | Default | Description | Example
--- | --- | --- | --- |
REGION | us-east-1 | AWS region to operate in |
SECURITY_GROUP | none | Coma-separated list of target security groups | SECURITY_GROUP='sg-3g2ghd78,sg-mn2948s8,sg-123456b7'
SECURITY_GROUP_LIMIT  | 40 | Maximum amount of IP rules to be placed into an each security group from the list
DEBUG | none | Print debug message to STDERR

For upload instruction read https://github.com/kleaver/rumbda/blob/master/README.md
