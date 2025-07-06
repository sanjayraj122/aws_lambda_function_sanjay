##!/bin/bash
#
## AWS Lambda Deployment Script for Spring Boot MySQL Application
#
#set -e
#
## Configuration
#FUNCTION_NAME="spring-boot-mysql-lambda"
#RUNTIME="java17"
#HANDLER="com.aws_lambda.StreamLambdaHandler::handleRequest"
#MEMORY_SIZE=1024
#TIMEOUT=30
#REGION="us-east-1"
#
## Environment variables for RDS
#DB_HOST="aws-user-db.cwxcqkc8q1ba.us-east-1.rds.amazonaws.com"
#DB_PORT="3306"
#DB_NAME="aws-user-db"
#DB_USERNAME="admin"
#DB_PASSWORD="Sanjay14253669"
#
#echo "Building the application..."
#mvn clean package -DskipTests
#
#echo "Creating deployment package..."
#JAR_FILE=$(find target -name "*.jar" -not -name "*sources*" -not -name "*javadoc*")
#
#if [ -z "$JAR_FILE" ]; then
#    echo "Error: JAR file not found in target directory"
#    exit 1
#fi
#
#echo "Found JAR file: $JAR_FILE"
#
## Check if Lambda function exists
#if aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>/test/null; then
#    echo "Updating existing Lambda function..."
#    aws lambda update-function-code \
#        --function-name $FUNCTION_NAME \
#        --zip-file fileb://$JAR_FILE \
#        --region $REGION
#
#    echo "Updating function configuration..."
#    aws lambda update-function-configuration \
#        --function-name $FUNCTION_NAME \
#        --runtime $RUNTIME \
#        --handler $HANDLER \
#        --memory-size $MEMORY_SIZE \
#        --timeout $TIMEOUT \
#        --environment Variables="{
#            DB_HOST=$DB_HOST,
#            DB_PORT=$DB_PORT,
#            DB_NAME=$DB_NAME,
#            DB_USERNAME=$DB_USERNAME,
#            DB_PASSWORD=$DB_PASSWORD,
#            SPRING_PROFILES_ACTIVE=prod
#        }" \
#        --region $REGION
#else
#    echo "Creating new Lambda function..."
#    aws lambda create-function \
#        --function-name $FUNCTION_NAME \
#        --runtime $RUNTIME \
#        --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role \
#        --handler $HANDLER \
#        --zip-file fileb://$JAR_FILE \
#        --memory-size $MEMORY_SIZE \
#        --timeout $TIMEOUT \
#        --environment Variables="{
#            DB_HOST=$DB_HOST,
#            DB_PORT=$DB_PORT,
#            DB_NAME=$DB_NAME,
#            DB_USERNAME=$DB_USERNAME,
#            DB_PASSWORD=$DB_PASSWORD,
#            SPRING_PROFILES_ACTIVE=prod
#        }" \
#        --region $REGION
#fi
#
#echo "Setting up API Gateway integration..."
## Create API Gateway if it doesn't exist
#API_ID=$(aws apigateway get-rest-apis --query "items[?name=='$FUNCTION_NAME-api'].id" --output text --region $REGION)
#
#if [ -z "$API_ID" ] || [ "$API_ID" = "None" ]; then
#    echo "Creating API Gateway..."
#    API_ID=$(aws apigateway create-rest-api \
#        --name "$FUNCTION_NAME-api" \
#        --description "API for Spring Boot MySQL Lambda" \
#        --region $REGION \
#        --query 'id' \
#        --output text)
#
#    # Get root resource ID
#    ROOT_ID=$(aws apigateway get-resources \
#        --rest-api-id $API_ID \
#        --region $REGION \
#        --query 'items[?path==`/`].id' \
#        --output text)
#
#    # Create proxy resource
#    RESOURCE_ID=$(aws apigateway create-resource \
#        --rest-api-id $API_ID \
#        --parent-id $ROOT_ID \
#        --path-part '{proxy+}' \
#        --region $REGION \
#        --query 'id' \
#        --output text)
#
#    # Create ANY method
#    aws apigateway put-method \
#        --rest-api-id $API_ID \
#        --resource-id $RESOURCE_ID \
#        --http-method ANY \
#        --authorization-type NONE \
#        --region $REGION
#
#    # Set up integration
#    aws apigateway put-integration \
#        --rest-api-id $API_ID \
#        --resource-id $RESOURCE_ID \
#        --http-method ANY \
#        --type AWS_PROXY \
#        --integration-http-method POST \
#        --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:YOUR_ACCOUNT_ID:function:$FUNCTION_NAME/invocations" \
#        --region $REGION
#
#    # Add permission for API Gateway to invoke Lambda
#    aws lambda add-permission \
#        --function-name $FUNCTION_NAME \
#        --statement-id api-gateway-invoke \
#        --action lambda:InvokeFunction \
#        --principal apigateway.amazonaws.com \
#        --source-arn "arn:aws:execute-api:$REGION:YOUR_ACCOUNT_ID:$API_ID/*/*/*" \
#        --region $REGION
#
#    # Deploy API
#    aws apigateway create-deployment \
#        --rest-api-id $API_ID \
#        --stage-name prod \
#        --region $REGION
#
#    echo "API Gateway URL: https://$API_ID.execute-api.$REGION.amazonaws.com/prod"
#fi
#
#echo "Deployment completed successfully!"
#echo "Function ARN: arn:aws:lambda:$REGION:YOUR_ACCOUNT_ID:function:$FUNCTION_NAME"
#echo "API Gateway URL: https://$API_ID.execute-api.$REGION.amazonaws