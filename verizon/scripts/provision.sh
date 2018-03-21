#!/bin/bash
#Change these flags to true if you have aws config already enabled in your account.
#Only one delivery channel and recorder allowed per account.
delivery_channel_exists="false"
config_recorder_exists="false"
#Temp dir to store keys
if [ ! -d "/tmp/tmpkeys" ]
then
  mkdir /tmp/tmpkeys
else
  DATE=$(date '+%Y-%m-%d-%H:%M:%S')
  mv /tmp/tmpkeys /tmp/tmpkeys-$DATE
  mkdir /tmp/tmpkeys
fi
#Generate ssh keys
ssh-keygen -t rsa -f /tmp/tmpkeys/id_rsa_bob -q -P ""
touch /tmp/tmpkeys/authorized_keys
cat /tmp/tmpkeys/id_rsa_bob.pub >> /tmp/tmpkeys/authorized_keys
rm -f /tmp/tmpkeys/id_rsa.pub
ssh-keygen -t rsa -f /tmp/tmpkeys/id_rsa_alice -q -P ""
cat /tmp/tmpkeys/id_rsa_alice.pub >> /tmp/tmpkeys/authorized_keys
#Create bucket to upload ssh keys
cd ../cf-templates
aws cloudformation create-stack --stack-name s3stack --template-body file://bucket_infra.yml  --output json
aws cloudformation wait stack-create-complete --stack-name s3stack
aws cloudformation describe-stacks --stack-name s3stack 
echo 'Bucket Created'
bucket_name=$(aws cloudformation describe-stacks --stack-name s3stack | grep -oP '(?<="OutputValue": ")[^"]*')
echo 'Uploading authorized_keys to bucket'
echo $bucket_name
aws s3 cp /tmp/tmpkeys/authorized_keys s3://${bucket_name}/
#aws s3 cp s3://$bucket_name/authorized_keys #Target dir
echo "Provisoning ec2 instance"
aws cloudformation create-stack --stack-name ec2infrastack --template-body file://ec2_infra.yml --parameters ParameterKey=S3BucketName,ParameterValue=${bucket_name} --output json --capabilities CAPABILITY_IAM
aws cloudformation wait stack-create-complete --stack-name ec2infrastack
public_ip=$(aws cloudformation describe-stacks --stack-name ec2infrastack | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | tail -n1 ) 
echo '################################'
echo 'Your public IP(if you wish to login):' ${public_ip}
echo '################################'
echo '############################################ End of EC2 Infra ############################################'
echo '##########################################################################################################'
echo "################################# Start of aws config rule setup and lambda deployment(Using SAM)#########"
#Delete existing deployable_lambda_infra.yml. New would be generated.
if [ -f "deployable_lambda_infra.yml" ]
then 
    rm -f deployable_lambda_infra.yml
fi     
echo "Package lambda code and copy to s3 bucket.Generate deployable stack."
aws cloudformation package --template lambda_infra.yml --s3-bucket ${bucket_name} --output-template-file deployable_lambda_infra.yml --force-upload
echo "Deploying lambda stack"
aws cloudformation deploy --template-file deployable_lambda_infra.yml --stack-name  lambdastack --capabilities CAPABILITY_IAM
echo 'Provision aws config rule'
aws cloudformation create-stack --stack-name configstack --template-body file://configrule_infra.yml --parameters ParameterKey=DeliveryChannelExists,ParameterValue=${delivery_channel_exists} ParameterKey=ConfigRecorderExists,ParameterValue=${config_recorder_exists} --output json --capabilities CAPABILITY_IAM
echo '################################## End of Lambda and aws config Infra ####################################'

