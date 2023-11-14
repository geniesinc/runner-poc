#!/usr/bin/env python3
'''
This script does all the operations needed to trigger a workflow job in our github org.  It is dependent on the environment variable 
GH_JOB_ID being set with the ID value of the Github actions job you are intending for this to trigger.
The idea here is that you can then deploy this code into more than one lambda in order to be targeting more than one job.
That means a lambda (which just executes this Python script) has a 1:1 relationship with a single Actions job.
You can configure the payload to meet whatever inputs you have setup for the receiving Actions job.

'''
import jwt
import time
import sys
import json
import urllib.request
from os import environ
import boto3
from botocore.exceptions import ClientError
# from cryptography.hazmat.backends import default_backend
# from cryptography.hazmat.primitives import serialization


def get_pem():

    secret_name = "github/workflows"
    region_name = "us-west-2"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e


    secret = get_secret_value_response['SecretString']
    return secret


def executeJob(token,artifact,jobid,repository,bucket_name,workflow_file,branch):
    headers = {
        'X-GitHub-Api-Version': '2022-11-28',
        'Accept': 'application/vnd.github+json',
        'Authorization': f'Bearer {token}'
    }
    payload = {"ref": f'{branch}', "inputs": {"artifact":f'{artifact}', "start-bucket-name":f'{bucket_name}'}}
    url = f'https://api.github.com/repos/geniesinc/{repository}/actions/workflows/{workflow_file}/dispatches'

    req = urllib.request.Request(url, headers=headers, data=json.dumps(payload).encode('utf-8'), method='POST')
    try:
        with urllib.request.urlopen(req) as response:
            print(str(response.status))
    except urllib.error.HTTPError as e:
        print(str(e.code))
        print(e.read())

def getInstallationToken(jwt_token, githubAppNumber):
    headers = {
        'X-GitHub-Api-Version': '2022-11-28',
        'Accept': 'application/vnd.github+json',
        'Authorization': f'Bearer {jwt_token}'
    }
    url = f'https://api.github.com/app/installations/{githubAppNumber}/access_tokens'

    req = urllib.request.Request(url, headers=headers, method='POST')
    with urllib.request.urlopen(req) as response:
        respJson = json.loads(response.read().decode('utf-8'))
        return respJson['token']

def getJWT():
    # pem = get_pem() # this is a todo, because I cannot figure out how to get the key to work when coming from AWS secrets.  Will just use file for now.
    pem = "./genies-art-runners.2023-07-17.private-key.pem"
    app_id = "360400" #this is not the same as the app number.

    # pem_bytes = serialization.load_pem_public_key(pem, backend=default_backend())

    # Open PEM
    with open(pem, 'rb') as pem_file:
        signing_key = jwt.jwk_from_pem(pem_file.read())

    payload = {
        # Issued at time
        'iat': int(time.time()),
        # JWT expiration time (10 minutes maximum)
        'exp': int(time.time()) + 600,
        # GitHub App's identifier
        'iss': app_id
    }

    jwt_instance = jwt.JWT()
    encoded_jwt = jwt_instance.encode(payload, signing_key, alg='RS256')

    return encoded_jwt

def lambda_handler(event, context):  
    bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    object_key = event["Records"][0]["s3"]["object"]["key"]
    
    artifact = object_key.split("/")[-1]
    
    print(f"Object key: {object_key}")
    
    jobid = "obsolete" #environ.get('GH_JOB_ID')
    repository = environ.get('GH_REPO')
    branch = environ.get('GH_BRANCH')
    workflow_file = environ.get('WORKFLOW_FILE')
    if not jobid or not repository:
        raise ValueError("GH_JOB_ID or GH_REPO environment variable is not set")

    githubAppNumber = "39576324" 
    #number of the github app in our org for this purpose.  This is not the same as the app ID.

    jwt = getJWT()

    token = getInstallationToken(jwt,githubAppNumber)

    executeJob(token,artifact,jobid,repository,bucket_name,workflow_file,branch)
    
    return {
        "statusCode": 200,
        "body": "Lambda function executed successfully"
    }