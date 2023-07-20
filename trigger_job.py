#!/usr/bin/env python3
# import requests
import jwt
import time
import sys
import json
import urllib.request


def executeJob(token, filename, jobid):
    # params = sys.argv[1]  # one liner null or empty string if nothing

    headers = {
        'X-GitHub-Api-Version': '2022-11-28',
        'Accept': 'application/vnd.github+json',
        'Authorization': f'Bearer {token}'
    }
    payload = {"ref": "main", "inputs": {"artifact":f'{filename}'}} #breaks if you give unexpected inputs? "name": "William", "home": "Knoxville, TN"
    url = f'https://api.github.com/repos/geniesinc/runner-poc/actions/workflows/{jobid}/dispatches'

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

    pem = "./genies-art-runners.2023-07-17.private-key.pem"
    app_id = "360400"

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

    # Create JWT
    jwt_instance = jwt.JWT()
    encoded_jwt = jwt_instance.encode(payload, signing_key, alg='RS256')

    return encoded_jwt



def lambda_handler(event, context):
    # Parse the S3 event data
    print("Received event: " + json.dumps(event, indent=2))
    
    # Extract the bucket name and object key
    bucket_name = event["Records"][0]["s3"]["bucket"]["name"]
    object_key = event["Records"][0]["s3"]["object"]["key"]
    
    # Extract the file name from the object key
    filename = object_key.split("/")[-1]
    
    # Print the file info
    print(f"Object key: {object_key}")
    
    jobid = "62953910"

    githubAppNumber = "39576324"

    jwt = getJWT()

    token = getInstallationToken(jwt,githubAppNumber)

    executeJob(token,filename,jobid)
    
    return {
        "statusCode": 200,
        "body": "Lambda function executed successfully"
    }


# if __name__ == '__main__':

#     jobid = "62953910"

#     githubAppNumber = "39576324"

#     jwt = getJWT()

#     token = getInstallationToken(jwt)

#     executeJob(token)




#if we want to use the requests library, uncomment these.
#We currently are using all python native libraries in this file.
# def executeJob(token):
#     params = sys.argv[1] #one liner null or empty string if nothing

#     headers = {'X-GitHub-Api-Version': '2022-11-28','Accept': 'application/vnd.github+json','Authorization':f'Bearer {token}'}
#     payload = {"ref":"main","inputs":{"name":"William","home":"Knoxville, TN"}}
#     r = requests.post(f'https://api.github.com/repos/geniesinc/runner-poc/actions/workflows/{jobid}/dispatches', headers=headers, data=json.dumps(payload))
#     print(str(r.status_code))

# def getInstallationToken(jwt):

#     headers = {'X-GitHub-Api-Version': '2022-11-28','Accept': 'application/vnd.github+json','Authorization':f'Bearer {jwt}'}
#     r = requests.post(f'https://api.github.com/app/installations/{githubAppNumber}/access_tokens', headers=headers) 
#     respJson = r.json()

#     return respJson.token