#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

function _logger() {
    echo -e "$(date) ${YELLOW}[*] $@ ${NC}"
}

source ./.env.sh

echo
echo "#########################################################"
_logger "[+] Verify the prerequisites environment"
echo "#########################################################"
echo

## DEBUG
echo "[x] Verify AWS CLI": $(aws  --version)
echo "[x] Verify git":     $(git  --version)
echo "[x] Verify jq":      $(jq   --version)
# echo "[x] Verify nano":    $(nano --version)
# echo "[x] Verify Docker":  $(docker version)
# echo "[x] Verify Docker Deamon":  $(docker ps -q)
# echo "[x] Verify nvm":     $(nvm ls)
# echo "[x] Verify Node.js": $(node --version)
echo "[x] Verify CDK":     $(cdk  --version)
# echo "[x] Verify Python":  $(python -V)
# echo "[x] Verify Python3": $(python3 -V)
# echo "[x] Verify kubectl":  $(kubectl version --client)
echo "[x] Verify java":    $(java -version)
echo "[x] Verify maven":   $(mvn  -version)

echo $AWS_ACCOUNT + $AWS_REGION + $AWS_S3_BUCKET + $AWS_RDS_CREDENTIAL_PAWSSWORD
currentPrincipalArn=$(aws sts get-caller-identity --query Arn --output text)
## Just in case, you are using an IAM role, we will switch the identity from your STS arn to the underlying role ARN.
currentPrincipalArn=$(sed 's/\(sts\)\(.*\)\(assumed-role\)\(.*\)\(\/.*\)/iam\2role\4/' <<< $currentPrincipalArn)
echo $currentPrincipalArn


echo
echo "#########################################################"
_logger "[+] Install node_modules CDK TypeScript"
echo "#########################################################"
echo

npm install
npm run build


started_time=$(date '+%d/%m/%Y %H:%M:%S')
echo
echo "#########################################################"
_logger "[+] [START] Deploy Elastic Beanstalk at ${started_time}"
echo "#########################################################"
echo


echo
echo "#########################################################"
_logger "[+] 1. [Springboot] Build war and jar"
echo "#########################################################"
echo


## Build Springboot project for Tomcat
cd Tomcat/ebproject
mvn install -DskipTests
cd ../..

## FIXME: 
## Build SpringBoot project for Java + PostgreSQL
# cd Springboot
# mvn install -DskipTests
# cd ..

echo
echo "#########################################################"
_logger "[+] 2. [AWS Infrastructure] S3, VPC, Cloud9"
echo "#########################################################"
echo

cdk bootstrap aws://${AWS_ACCOUNT}/${AWS_REGION} \
    --bootstrap-bucket-name ${AWS_S3_BUCKET}        \
    --termination-protection                        \
    --tags cost=Job4U 
## export CDK_NEW_BOOTSTRAP=1
## cdk bootstrap aws://${AWS_ACCOUNT}/${AWS_REGION} --show-template -v

## DEBUG
rm -rf cdk.out/*.* cdk.context.json

## cdk diff $AWS_CDK_STACK
## cdk synth $AWS_CDK_STACK
## cdk deploy $AWS_CDK_STACK --require-approval never
cdk deploy --all --require-approval never

## FIXME: 
# echo HostInstanceDBMySQL=$(aws rds --region ${AWS_REGION} describe-db-instances --max-results 1 --query "DBInstances[${AWS_RDS_INSTANCE_NAME}].Endpoint.Address" --output text)
# echo ${HostInstanceDBMySQL}

# echo mysql -h ${HostInstanceDBMySQL} -u ${AWS_RDS_CREDENTIAL_USERNAME} ${AWS_RDS_DATABASE_NAME}
# echo source ./AddRecordDB-RDS.sql;
# echo exit;

## Danger!!! Cleanup
# echo "Cleanup ..."
# cdk destroy --all --require-approval never


ended_time=$(date '+%d/%m/%Y %H:%M:%S')
echo
echo "#########################################################"
echo -e "${RED} [END] Elastic Beanstalk at ${ended_time} - ${started_time} ${NC}"
echo "#########################################################"
echo
