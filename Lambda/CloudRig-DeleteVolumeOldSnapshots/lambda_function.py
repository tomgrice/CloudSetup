import json
import boto3
import botocore

def lambda_handler(event, context):

    DryRunSetting = False
    SNAPSHOT_REGION = event['region']
    SNAPSHOT_ID = event['detail']['snapshot_id'].split('/')[1]
    
    #SNAPSHOT_REGION = 'eu-west-2'
    #SNAPSHOT_ID = 'snap-098ea2061bdf2dc6c'
    
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

    snapshot = res.Snapshot(SNAPSHOT_ID)
    
    print(snapshot)
    
    snapshot_name = get_snapshot_tag(SNAPSHOT_ID, 'Name')
    snap_and_delete = get_snapshot_tag(SNAPSHOT_ID, 'SnapAndDelete').lower() == "true"
    
    if snap_and_delete == True:
        if snapshot_name != '':
            volume = res.Volume(snapshot.volume_id)
            volume.delete(DryRun=DryRunSetting)
            
            delete_snapshots(snapshot_name,SNAPSHOT_ID)
            