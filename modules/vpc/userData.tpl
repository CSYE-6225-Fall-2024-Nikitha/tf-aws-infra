#!/bin/bash
set -e 

ENV_FILE="/home/ubuntu/webapp/.env"

if [ ! -d "/home/ubuntu/webapp" ]; then
  echo "Directory /home/ubuntu/webapp does not exist, exiting..."
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, installing..."
    sudo apt-get update -y
    sudo apt-get install -y jq
else
    echo "jq is already installed."
fi

sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sudo chown -R csye6225:csye6225 /home/ubuntu/webapp
sudo chmod -R 755 /home/ubuntu/
sudo chmod -R 755 /home/ubuntu/webapp





sudo tee "$ENV_FILE" <<EOF
DB_HOST=${DB_HOST}
DB_USER=${DB_USER}
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id rds-password-kms \
  --query 'SecretString' \
  --output text)
DB_NAME=${DB_NAME}
DB_PORT=${DB_PORT}
DB_DIALECT=${DB_DIALECT}
S3_BUCKET_ID=${S3_BUCKET_ID}
AWS_REGION=${AWS_REGION}
SNS_TOPIC_ARN=${SNS_TOPIC_ARN}
EOF

sudo chown -R csye6225:csye6225 /home/ubuntu/
sudo chmod -R 755 /home/ubuntu/
sudo chown -R csye6225:csye6225 /home/ubuntu/webapp/.env
sudo chmod -R 755 /home/ubuntu/webapp/.env




CLOUDWATCH_CONFIG_PATH="/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json"

if [ -f "$CLOUDWATCH_CONFIG_PATH" ]; then
    sudo systemctl enable amazon-cloudwatch-agent

    sudo systemctl restart amazon-cloudwatch-agent

    echo "CloudWatch agent configured and restarted successfully."
else
    echo "CloudWatch configuration file not found at $CLOUDWATCH_CONFIG_PATH."
    exit 1
fi

touch /opt/setDataBase.sh


if [ -f "$ENV_FILE" ]; then
  echo ".env file created successfully:"
  cat "$ENV_FILE"
else
  echo "Failed to create .env file"
  exit 1
fi
