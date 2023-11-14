data "aws_ecr_authorization_token" "token" {}

resource "aws_ecr_repository" "repository" {
  name                 = "lambda-github-action-trigger"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  lifecycle {
    ignore_changes = all
  }
}


# data "aws_ecr_repository" "repository" {
#   name = "lambda-github-action-trigger"
# }

output "aws_ecr_repository" {
    value = aws_ecr_repository.repository.repository_url
}


# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "PrivateReadOnly",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": [
#           "arn:aws:iam::608392574519:root",
#           "arn:aws:iam::660148697462:root",
#           "arn:aws:iam::583625886946:root",
#           "arn:aws:iam::205215413168:root"
#         ]
#       },
#       "Action": [
#         "ecr:BatchCheckLayerAvailability",
#         "ecr:BatchGetImage",
#         "ecr:DescribeImageScanFindings",
#         "ecr:DescribeImages",
#         "ecr:DescribeRepositories",
#         "ecr:GetDownloadUrlForLayer",
#         "ecr:GetLifecyclePolicy",
#         "ecr:GetLifecyclePolicyPreview",
#         "ecr:GetRepositoryPolicy",
#         "ecr:ListImages",
#         "ecr:ListTagsForResource"
#       ]
#     },
#     {
#       "Sid": "LambdaECRImageRetrievalPolicy",
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Action": [
#         "ecr:BatchGetImage",
#         "ecr:DeleteRepositoryPolicy",
#         "ecr:GetDownloadUrlForLayer",
#         "ecr:GetRepositoryPolicy",
#         "ecr:SetRepositoryPolicy"
#       ],
#       "Condition": {
#         "StringLike": {
#           "aws:sourceArn": [
#             "arn:aws:lambda:us-west-2:583625886946:function:*",
#             "arn:aws:lambda:us-west-2:608392574519:function:*",
#             "arn:aws:lambda:us-west-2:660148697462:function:*",
#             "arn:aws:lambda:us-west-2:205215413168:function:*"
#           ]
#         }
#       }
#     }
#   ]
# }