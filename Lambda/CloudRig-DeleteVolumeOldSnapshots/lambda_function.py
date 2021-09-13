import json
import boto3
import botocore

def lambda_handler(event, context):

    DryRunSetting = False
    SNAPSHOT_REGION = event['region']
    SNAPSHOT_ID = event['detail']['snapshot_id'].split('/')[1]
    
    #SNAPSHOT_REGION = 'eu-west-2'
    #SNAPSHOT_ID = 'snap-00934cec8fdc15ec2'
    
    ec2 = boto3.client('ec2',region_name=SNAPSHOT_REGION)
    res = boto3.resource('ec2',region_name=SNAPSHOT_REGION)
    
    def get_snapshot_tag(snapshot_id, tag_key):
        snapshot = res.Snapshot(snapshot_id)
        
        snapshot_tags = snapshot.tags
        
        tag_value = ''
        for tag in snapshot_tags:
            if tag["Key"] == tag_key:
                tag_value = tag["Value"]
                
        return tag_value
        
        
    def deregister_image(snapid):
        images = ec2.describe_images(Filters=[{'Name': 'name', 'Values':[snapid]}])['Images']
        
        result = []
        for image in images:
            imageid = image['ImageId']
            image_res = res.Image(imageid)
            dereg_image = image_res.deregister(DryRun=DryRunSetting)
            result.append(dereg_image)
                
        return result
        
    def delete_snapshots(name,immune_snapshotid):
        snapshots = ec2.describe_snapshots(Filters=[{'Name': 'tag:Name', 'Values':[name]}])['Snapshots']
        
        result = []
        for snap in snapshots:
            snapshotid = snap['SnapshotId']
            if snapshotid != immune_snapshotid:
                snapshot_res = res.Snapshot(snapshotid)
                delete_snap = snapshot_res.delete(DryRun=DryRunSetting)
                
                result.append(delete_snap)
                
        return result
        
    def create_image(snapname, snapid):
        ami = ec2.register_image(
            Name=snapname, 
            Description=snapname + ' Automatic AMI', 
            BlockDeviceMappings=[
                {
                    'DeviceName': '/dev/sda1',
                    'Ebs': {
                        'DeleteOnTermination': False,
                        'SnapshotId': snapid,
                        'VolumeType': 'gp2'
                    }
                },
            ],
            Architecture='x86_64', 
            RootDeviceName='/dev/sda1', 
            DryRun=False, 
            VirtualizationType='hvm', 
            EnaSupport=True
        )
        
        return ami

    snapshot = res.Snapshot(SNAPSHOT_ID)
    
    print(snapshot)
    
    snapshot_name = get_snapshot_tag(SNAPSHOT_ID, 'Name')
    snap_and_delete = get_snapshot_tag(SNAPSHOT_ID, 'SnapAndDelete').lower() == "true"
    
    if snap_and_delete == True:
        if snapshot_name != '':
            volume = res.Volume(snapshot.volume_id)
            volume.delete(DryRun=DryRunSetting)
            print(deregister_image(snapshot_name))
            print(delete_snapshots(snapshot_name,SNAPSHOT_ID))
            print(create_image(snapshot_name, SNAPSHOT_ID))
            