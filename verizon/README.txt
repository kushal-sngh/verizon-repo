## verizon-assignment
kushal Singh


## Tools and technologies used in Solution ##

1. AWS Config
2. AWS Cloudformation
3. AWS S3
4. AWS EC2
5. AWS IAM
6. AWS Lambda
7. Shell Script

##Solution is desgined and implemented as per the requirements came in email.**

##Solution's outcome would be following:- 
1. Provision of EC2 instance.
2. Only bob and alice are allowed to ssh login from the respective ip's.
3. Host also allows web traffic from 443 port, which can be further extended to hardening the web server. ( I was not sure about web hosting requirements,Little more explanation required,there are multiple other good ways to do it on aws.)
4. Provision of AWS Config service.
5. Deploying a rule which is scopped to capture all IAM User resources.
6. A custom lambda function which will evaluate user compliance rules.
 

## Assumptions ##

1. Since I do not have windows environment on my desktop this solution will work in linux environment only.Windows user can use cygwin.
2. AWS CLI is installed on the host. 
3. AWS Account.


## Testing ##
1. Unzip the file
2. cd to /verizon/scripts
3. Run ./provision.sh
4. copy public ip from console.
5. ssh -i <<your private key path>> bob@<<public ip>>
6. Login to console and go to AWS Config dashboard which must show all the COMPLIANT and NON-COMPLIANT users.

Note: If you have aws config already enabled in your account then change the flags in script from false to true.

