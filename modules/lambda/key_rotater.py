import boto3
import os
import json
from datetime import datetime, timedelta, timezone
from botocore.exceptions import ClientError

# =====================================
# Environment Variables Configuration
# =====================================

# Rotation policy configs
key_age = os.environ['KEY_AGE']                      # Number of days after which key is considered expired
expire_key_age = os.environ['DELETE_KEY']            # Days after which disabled keys are deleted

# Notification and Secrets management
sender_email = os.environ['ADMIN_EMAIL']             # Email sender for SES
admin_user = os.environ['ADMIN_USERNAME']            # IAM username of admin
admin_group = os.environ['ADMIN_GROUP']              # IAM group allowed access to secrets
account_id = os.environ['AWS_ACCOUNT_ID']            # AWS account ID
role_arn = os.environ['ROLE_ARN']                    # Role ARN that can update secrets

# User tag to skip processing
tag_key = os.environ['TAG_KEY']
tag_value = os.environ['TAG_VALUE']


# ======================
# IAM Key Management
# ======================

def create_access_key(iam, user_name):
    """
    Creates a new access key for the given IAM user.
    """
    try:
        response = iam.create_access_key(UserName=user_name)
        return response['AccessKey']
    except ClientError as e:
        print(f"Failed to create access key for user {user_name}: {e}")
        return None      


def disable_access_key(iam, user_name, access_key_id):
    """
    Disables an IAM access key and tags it with a future deletion date.
    """
    try:
        iam.update_access_key(UserName=user_name, AccessKeyId=access_key_id, Status='Inactive')
        iam.tag_user(UserName=user_name, Tags=[
            {'Key': 'DeleteOn', 'Value': (datetime.now(timezone.utc) + timedelta(days=int(expire_key_age))).strftime("%Y-%m-%d")}
        ])
    except ClientError as e:
        print(f"Failed to disable access key {access_key_id} for user {user_name}: {e}")


def delete_access_key(iam, access_key_id):
    """
    Permanently deletes an IAM access key.
    """
    try:
        iam.delete_access_key(AccessKeyId=access_key_id)
    except ClientError as e:
        print(f"Failed to delete access key {access_key_id}: {e}")


# ======================
# AWS Secrets Manager
# ======================

def secret_store(user_name, access_key, secret_key):
    """
    Stores new credentials in AWS Secrets Manager and configures a resource policy 
    to allow access by the user, admin, group, and IAM role.
    """
    secrets_client = boto3.client('secretsmanager')

    secret_values = {
        'username': user_name,
        'Access_key': access_key,
        'Secret_key': secret_key
    }

    secret_value = json.dumps(secret_values)
    secret_name = f'{user_name}-credentials-5'

    try:
        # Try creating the secret
        secret_response = secrets_client.create_secret(
            Name=secret_name,
            SecretString=secret_value,
            Tags=[{'Key': 'CreatedFor', 'Value': user_name}]
        )

        # Attach a policy to allow only specific principals
        resource_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": f"arn:aws:iam::{account_id}:user/{user_name}"},
                    "Action": "secretsmanager:GetSecretValue",
                    "Resource": f"{secret_response['ARN']}"
                },
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": f"arn:aws:iam::{account_id}:user/{admin_user}"},
                    "Action": "secretsmanager:GetSecretValue",
                    "Resource": f"{secret_response['ARN']}"
                },
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": f"arn:aws:iam::{account_id}:group/{admin_group}"},
                    "Action": "secretsmanager:GetSecretValue",
                    "Resource": f"{secret_response['ARN']}"
                },
                {
                    "Effect": "Allow",
                    "Principal": {"AWS": f"{role_arn}"},
                    "Action": "secretsmanager:Update*",
                    "Resource": f"{secret_response['ARN']}"
                }
            ]
        }

        secrets_client.put_resource_policy(
            SecretId=secret_response['ARN'],
            ResourcePolicy=json.dumps(resource_policy)
        )

    except:
        # If secret already exists, update it
        try:
            print("Secret already exists, updating secret value")
            secrets_client.update_secret(
                SecretId=secret_name,
                SecretString=secret_value
            )
        except ClientError as e:
            print(f"Failed to create or update secret for user {user_name}: {e}")


# ======================
# Email Notification
# ======================

def notify_user(user_name, message):
    """
    Sends a notification email to the user via AWS SES.
    """
    subject = "Access Key Notification"
    body = f"Dear {user_name},\n\n{message}\n\nRegards,\nAdmin"
    sender = sender_email
    recipient = user_name

    ses = boto3.client('ses')
    try:
        ses.send_email(
            Source=sender,
            Destination={'ToAddresses': [recipient]},
            Message={
                'Subject': {'Charset': 'UTF-8', 'Data': subject},
                'Body': {'Text': {'Charset': 'UTF-8', 'Data': body}}
            }
        )
        print(f"Email notification sent to user {user_name}")
    except Exception as e:
        print(f"Failed to send email to {user_name}: {e}")


# ======================
# Per-User Processing Logic
# ======================

def process_user(iam, user):
    """
    Evaluates the user's access key age, status, and handles rotation, 
    disabling, deletion, and notification logic.
    """
    user_name = user['UserName']
    access_keys = iam.list_access_keys(UserName=user_name)['AccessKeyMetadata']
    num_keys = len(access_keys)

    now = datetime.now(timezone.utc)
    n_days = int(key_age)
    cutoff_date = now - timedelta(days=n_days)

    if num_keys > 0:
        expired_keys = [k for k in access_keys if k['CreateDate'].replace(tzinfo=timezone.utc) < cutoff_date]
        active_keys = [k for k in access_keys if k['Status'] == 'Active']
        disabled_keys = [k for k in access_keys if k['Status'] == 'Inactive']

        # ========== Case: 2 Keys ==========
        if num_keys == 2:
            if len(active_keys) == 2:
                notify_user(user_name, "User already has two active keys. Moving to the next user")
                return

            elif len(active_keys) == 1 and len(disabled_keys) == 1:
                if disabled_keys[0]['AccessKeyId'] == expired_keys[0]['AccessKeyId']:
                    print("Checking if key is expired by date tag")
                elif active_keys[0]['AccessKeyId'] == expired_keys[0]['AccessKeyId']:
                    print(f"{user_name}: Active key is expired. Rotating and deleting old key")
                    delete_access_key(iam, disabled_keys[0]['AccessKeyId'])
                    disable_access_key(iam, user_name, active_keys[0]['AccessKeyId'])
                    new_key = create_access_key(iam, user_name)
                    if new_key:
                        disable_access_key(iam, user_name, expired_keys[0]['AccessKeyId'])
                        secret_store(user_name, new_key['AccessKeyId'], new_key['SecretAccessKey'])
                        notify_user(user_name, f"Your access key has been rotated. \nAccess Key: {new_key['AccessKeyId']} \nSecret Key: {new_key['SecretAccessKey']}")

            for key in disabled_keys:
                try:
                    tags = iam.list_user_tags(UserName=user_name)['Tags']
                    delete_date = next((tag['Value'] for tag in tags if tag['Key'] == 'DeleteOn'), None)
                    delete_date = datetime.strptime(delete_date, "%Y-%m-%d") if delete_date else now + timedelta(days=int(expire_key_age))
                except:
                    delete_date = now + timedelta(days=int(expire_key_age))

                if delete_date <= now:
                    delete_access_key(iam, key['AccessKeyId'])
                else:
                    notify_user(user_name, f"Key {key['AccessKeyId']} is already disabled and will be deleted on {delete_date.strftime('%Y-%m-%d')}")

            if expired_keys:
                new_key = create_access_key(iam, user_name)
                if new_key:
                    disable_access_key(iam, user_name, expired_keys[0]['AccessKeyId'])
                    secret_store(user_name, new_key['AccessKeyId'], new_key['SecretAccessKey'])
                    notify_user(user_name, f"Rotated your expired key. Access Key: {new_key['AccessKeyId']}, Secret: {new_key['SecretAccessKey']}")
            else:
                notify_user(user_name, "No expired key found to rotate.")

        # ========== Case: 1 Key ==========
        elif num_keys == 1:
            key = access_keys[0]
            if key['Status'] == 'Inactive':
                for key in disabled_keys:
                    try:
                        tags = iam.list_user_tags(UserName=user_name)['Tags']
                        delete_date = next((tag['Value'] for tag in tags if tag['Key'] == 'DeleteOn'), None)
                        delete_date = datetime.strptime(delete_date, "%Y-%m-%d") if delete_date else now + timedelta(days=int(expire_key_age))
                    except:
                        delete_date = now + timedelta(days=int(expire_key_age))

                    if delete_date <= now:
                        delete_access_key(iam, key['AccessKeyId'])
                    else:
                        notify_user(user_name, f"Disabled key {key['AccessKeyId']} will be deleted after {delete_date.strftime('%Y-%m-%d')}")
            else:
                if expired_keys:
                    disable_access_key(iam, user_name, key['AccessKeyId'])
                    new_key = create_access_key(iam, user_name)
                    if new_key:
                        disable_access_key(iam, user_name, expired_keys[0]['AccessKeyId'])
                        secret_store(user_name, new_key['AccessKeyId'], new_key['SecretAccessKey'])
                        notify_user(user_name, f"Rotated your expired key. Access Key: {new_key['AccessKeyId']}, Secret: {new_key['SecretAccessKey']}")
                else:
                    print(f"{user_name}: 1 key found, still valid. Skipping...")

        # ========== Case: 0 Keys ==========
        else:
            print(f"{user_name}: No access keys found. Skipping...")

# ======================
# Lambda Entry Point
# ======================

def lambda_handler(event, context):
    """
    Lambda handler function that lists all IAM users, checks their tags,
    and processes them unless marked to be skipped.
    """
    iam = boto3.client('iam')
    response = iam.list_users()

    for user in response['Users']:
        tags = iam.list_user_tags(UserName=user['UserName'])['Tags']
        skip_user = any(tag['Key'] == tag_key and tag['Value'] == tag_value for tag in tags)

        if not skip_user:
            print(f"{user['UserName']} has no skip tag. Processing...")
            process_user(iam, user)
        else:
            print(f"{user['UserName']} is skipped due to tag {tag_key}={tag_value}.")

    return {
        'statusCode': 200,
        'body': 'Access keys checked and updated successfully.'
    }
