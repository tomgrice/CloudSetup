import json
import boto3
import botocore

EC2_REGION = 'eu-west-2'

def lambda_handler(event, context):
    
    INSTANCE_NAME = event.get('queryStringParameters')
    if INSTANCE_NAME != None:
        INSTANCE_NAME = INSTANCE_NAME.get('instance-name')
        
    #INSTANCE_NAME = 'trmg-cloud'
        
    if INSTANCE_NAME == None:
        return 'No instance name defined'

    output = ''

    ec2 = boto3.client('ec2',region_name=EC2_REGION)
    res = boto3.resource('ec2', region_name=EC2_REGION)
    
    running_instances = ec2.describe_instances( Filters=[{'Name': 'tag:Name', 'Values': [INSTANCE_NAME]},{'Name': 'instance-state-name', 'Values': ['pending','running','shutting-down','stopping','stopped']}] )['Reservations']
    pending_snapshots = ec2.describe_snapshots( Filters=[{'Name': 'tag:Name', 'Values': [INSTANCE_NAME]},{'Name': 'status', 'Values': ['pending']}] )['Snapshots']
    
    if len(running_instances) == 0 and len(pending_snapshots) == 0:
        print('Starting instance: ' + INSTANCE_NAME)
        ami_images = ec2.describe_images( Filters=[{'Name': 'name', 'Values': [INSTANCE_NAME]}] )['Images']
        
        for ami_image in ami_images:
            image_id = ami_image['ImageId']
            
        
        instance_result = ec2.run_instances(
            LaunchTemplate={
                'LaunchTemplateName': 'LaunchCloudRig'
            },
            IamInstanceProfile={'Name': 'CloudGamingInstanceRole'},
            ImageId=image_id,
            MaxCount=1,
            MinCount=1
            )
            
        instance_id = instance_result['Instances'][0]['InstanceId']
        instance_waiter = ec2.get_waiter('instance_running')
        
        instance_waiter.wait(InstanceIds=[instance_id])
        
        print(instance_result)
        
        
        output = 'Instance created with IP: ' + res.Instance(instance_id).public_ip_address
    else:
        if len(pending_snapshots) > 0:
            output = 'Snapshot from previous instance still pending.'
        else:
            output = 'Instance ' + INSTANCE_NAME + ' is already running with IP: ' + running_instances[0]['Instances'][0]['PublicIpAddress']
            
    return output
    