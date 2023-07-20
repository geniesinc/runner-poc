# runner-poc

This repo contains the demo actions jobs that were used to demo this process:
https://docs.google.com/drawings/d/1R6n6SzTEo3B4bZyUlyGNn0YGQNiz2_MA_w-z343CmM4/edit?usp=sharing

Fork this repo if you'd like to play around with the job I have defined here.

The terraform code here manages the infra made for the demo.  Be sure to be locally logged into the infra account and then run your init command.  Note, the state file for this is located here, so if you tinker with it, you need to inform anyone else who is using this repo to pull the latest.

The trigger_job.py contains the code the lambda job needs to do its purpose as defined in the diagram.  It is packed into a docker image and deployed manually to the lambda.

Deploying lambda image:
docker buildx build -t lambda-github-action-trigger . --platform=linux/amd64
docker tag lambda-github-action-trigger:latest 583625886946.dkr.ecr.us-west-2.amazonaws.com/lambda-github-action-trigger:latest
docker push 583625886946.dkr.ecr.us-west-2.amazonaws.com/lambda-github-action-trigger:latest



Dependencies:
- A github app installed to the org, providing a headless user to do the tasks.
- Github app setup with proper permissions to access actions.
- Private key from the github app for API auth and security purposes.
- Job configured to be triggered manually (this is part of writing the yaml of your job anyway).



example event that is received:
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "us-west-2",
      "eventTime": "2023-07-18T18:03:19.634Z",
      "eventName": "ObjectCreated:Put",
      "userIdentity": {
        "principalId": "AWS:AROAYPYWQJTRJP4IVUR6U:GitHubActions"
      },
      "requestParameters": {
        "sourceIPAddress": "54.201.54.214"
      },
      "responseElements": {
        "x-amz-request-id": "RC89AW4KYCJKAKX9",
        "x-amz-id-2": "tKu4pYgRTpK65zJXNd48FXhSF1nHC30jOpAhJXP6MOP/Y1djG9532tq7B+gdIdqhlNYwJDkJdzDwsBCdqf0LGQwdoCA5GPde"
      },
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "tf-s3-lambda-20230718162357841200000001",
        "bucket": {
          "name": "runner-poc-bucket",
          "ownerIdentity": {
            "principalId": "AWGB7QJE8CEXR"
          },
          "arn": "arn:aws:s3:::runner-poc-bucket"
        },
        "object": {
          "key": "TEST_FILE.TXT",
          "size": 25,
          "eTag": "55431e58b4e2a3d88b121e18ee8196b2",
          "versionId": "j8wVzEVhckQ8MMzOrqgL0_nGmkcxqo1n",
          "sequencer": "0064B6D3E798EB694D"
        }
      }
    }
  ]
}
