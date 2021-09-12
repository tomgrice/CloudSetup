import json
import boto3
import botocore

def lambda_handler(event, context):
    # TODO implement

    GAMING_INSTANCE_REGION = event['region']
    GAMING_INSTANCE_ID = event['detail']['instance-id']

    ec2 = boto3.client('ec2',region_name=GAMING_INSTANCE_REGION)
    res_client = boto3.resource('ec2', region_name=GAMING_INSTANCE_REGION)

    instance_data = ec2.describe_instances( Filters=[{'Name': 'instance-id', 'Values': [GAMING_INSTANCE_ID]}] )['Reservations']['Instances'][0]
    instance_volume = ec2.describe_volumes( Filters=[{'Name': 'attachment.instance-id', 'Values': [GAMING_INSTANCE_ID]}] )['Volumes'][0]

    return {
        'statusCode': 200,
        'body': json.dumps(instance_data['tags'])
    }