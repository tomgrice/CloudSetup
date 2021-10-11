import json
import boto3
import botocore

def lambda_handler(event, context):

    EC2_REGION = 'eu-west-2'
    SERVER_KEY = '879CXmQn0PRQr3m3ehWR7Xf4c9bgGLN1wpUFZGI-fLum15FPUTR_Bf9TXrSpLSvOeAQ3jKDuKlXRfjkJ83k89pnhhLa4NJqy5fQR893f5Mp1CKxdvgv7Tt3wLjCcHc1MMIJICzc0wA6YMBZVwZQ4H89mgfxQJVRueU-cv7lkww0'
    dyndb = boto3.resource('dynamodb')
    ec2 = boto3.client('ec2',region_name=EC2_REGION)
    res = boto3.resource('ec2', region_name=EC2_REGION)

    dyndb_table = dyndb.Table('ionoservers')
    result = dyndb_table.query(
        KeyConditionExpression=boto3.dynamodb.conditions.Key('ServerKey').eq(SERVER_KEY)
    )

    print(result)

    user_data = json.dumps(result['Items'][0])
    INSTANCE_NAME = 'trmg-cloud-1'

    
    existing_instances = ec2.describe_instances( Filters=[{'Name': 'tag:Name', 'Values': [INSTANCE_NAME]}])['Reservations']
    existing_snapshots = ec2.describe_snapshots( Filters=[{'Name': 'tag:Name', 'Values': [INSTANCE_NAME]}] )['Snapshots']
    existing_images = ec2.describe_images( Filters=[{'Name': 'tag:Name', 'Values': [INSTANCE_NAME]}] )['Images']

    if(len(existing_instances) > 0):
        return 'There is already an existing instance with this name.'

    if(len(existing_snapshots) > 0):
        return 'There are existing snapshots with this instance name.'

    if(len(existing_images) > 0):
        return 'There are existing AMI images with this name.'

    instance_result = ec2.run_instances(
        BlockDeviceMappings=[
            {
                'DeviceName': '/dev/sda1',
                'Ebs': {
                    'DeleteOnTermination': False,
                    'Iops': 6000,
                    'VolumeSize': 256,
                    'VolumeType': 'gp3',
                    'Throughput': 300
                }
            }
        ],
        LaunchTemplate={
            'LaunchTemplateName': 'trmg-cloud-1-template'
        },
        TagSpecifications=[
            {
                'ResourceType': 'instance'|'volume'|'snapshot',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': INSTANCE_NAME
                    },
                    {
                        'Key': 'SnapAndDelete',
                        'Value': 'True'
                    },
                ]
            },
        ],
        IamInstanceProfile={'Name': 'CloudGamingInstanceRole'},

        ImageId='ami-0f9ba0563c3ae6414',
        UserData=user_data,
        MaxCount=1,
        MinCount=1
    )
            
    instance_id = instance_result['Instances'][0]['InstanceId']
    instance_waiter = ec2.get_waiter('instance_running')
        
    instance_waiter.wait(InstanceIds=[instance_id])
        
    print(instance_result)
        
        
    return 'Instance created with IP: ' + res.Instance(instance_id).public_ip_address
    



print(lambda_handler('',''))