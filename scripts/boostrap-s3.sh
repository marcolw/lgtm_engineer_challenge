# 1. Create S3 Bucket (must be globally unique)
BUCKET_NAME="lgtm-engineer-challenge-tf-state-058264095432" # REPLACE WITH YOUR UNIQUE NAME
REGION="ap-southeast-2"

aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION

# 2. Enable Versioning (Highly Recommended for state safety)
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# 3. Create DynamoDB Table for Locking (required for production locking)
aws dynamodb create-table \
    --table-name lgtm-engineer-challenge-tf-lock \
    --region $REGION \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

echo "S3 Bucket and DynamoDB table created successfully."
