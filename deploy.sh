#!/bin/bash
set -e
exit 1 #temporary: testing notification for failure status


echo "Uploading artifact to S3"
aws s3 cp target/*.jar "s3://${ARTIFACT_BUCKET}/app.jar"

echo "Triggering deployment via SSM"
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$EC2_INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "{\"commands\":[
    \"sudo mkdir -p /opt/app\",
    \"sudo aws s3 cp s3://${ARTIFACT_BUCKET}/app.jar /opt/app/app.jar\",
    \"sudo tee /etc/systemd/system/cicd-challenge-app.service > /dev/null << 'EOF'\n[Unit]\nDescription=Java Web App For The CICD Challenge\nAfter=network.target\n\n[Service]\nExecStart=/usr/bin/java -jar /opt/app/app.jar --server.port=8080\nRestart=always\nUser=ec2-user\n\n[Install]\nWantedBy=multi-user.target\nEOF\",
    \"sudo systemctl daemon-reload\",
    \"sudo systemctl enable cicd-challenge-app\",
    \"sudo systemctl restart cicd-challenge-app\"
  ]}" \
  --query "Command.CommandId" \
  --output text)

echo "Command ID = $COMMAND_ID"

for i in $(seq 1 10); do
  STATUS=$(aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$EC2_INSTANCE_ID" \
    --query "Status" \
    --output text)
  echo "SSM command status: $STATUS"
  if [ "$STATUS" = "Success" ]; then
    break
  elif [ "$STATUS" = "Failed" ] || [ "$STATUS" = "Cancelled" ] || [ "$STATUS" = "TimedOut" ]; then
    echo "SSM deployment failed with status: $STATUS"
    exit 1
  fi
  sleep 5
done

if [ "$STATUS" != "Success" ]; then
  echo "SSM command did not reach Success state within timeout"
  exit 1
fi