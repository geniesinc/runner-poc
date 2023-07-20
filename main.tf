resource "aws_s3_bucket" "runner_poc_bucket" {
  bucket = "runner-poc-bucket"

  # Enable versioning
  versioning {
    enabled = true
  }

  # Grant bucket permissions
  acl = "private"

#   lifecycle_rule {
#     id      = "owner-access"
#     status  = "Enabled"
#     prefix  = ""
#     enabled = true

#     # transition {
#     #   days          = 30
#     #   storage_class = "GLACIER"
#     # }

#     # noncurrent_version_transition {
#     #   days          = 30
#     #   storage_class = "GLACIER"
#     # }

#     # expiration {
#     #   days = 365
#     # }

#     tags = {
#       "owner" = "583625886946"
#     }
#   }

}

# Create the S3 bucket (runner-poc-testing-result)
resource "aws_s3_bucket" "runner_poc_testing_result" {
  bucket = "runner-poc-testing-result"

  # Enable versioning
  versioning {
    enabled = true
  }

  # Grant bucket permissions (same as runner-poc-bucket)
  acl = aws_s3_bucket.runner_poc_bucket.acl

}



# Create the Lambda function
resource "aws_lambda_function" "trigger_github_action" {
  function_name = "TriggerGithubAction"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "trigger_job.lambda_handler"
#   runtime       = "provided.al2"
  package_type  = "Image"

  image_uri = "${aws_ecr_repository.repository.repository_url}:latest"

  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}


# Set up the S3 bucket event notification
resource "aws_s3_bucket_notification" "runner_poc_bucket_notification" {
  bucket = aws_s3_bucket.runner_poc_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.trigger_github_action.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ""
  }
}


resource "aws_lambda_permission" "test" {
    statement_id  = "AllowS3Invoke"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.trigger_github_action.function_name}"
    principal = "s3.amazonaws.com"
    source_arn = "arn:aws:s3:::${aws_s3_bucket.runner_poc_bucket.id}"
}



resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "AllowBucketAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.runner_poc_bucket.arn}/*",
      "${aws_s3_bucket.runner_poc_testing_result.arn}/*"
    ]

    # principals {
    #   type        = "AWS"
    #   identifiers = [
    #     "arn:aws:iam::583625886946:role/AWSReservedSSO_AWSAdministratorAccess_c30ca6b6ac210f51/whibbard@genies.com",
    #     "arn:aws:iam::583625886946:role/genies_deployer-role"
    #   ]
    # }
  }
}

resource "aws_iam_policy" "bucket_policy" {
  name        = "S3BucketAccessPolicy"
  policy      = data.aws_iam_policy_document.bucket_policy.json
}

# resource "aws_iam_role_policy_attachment" "bucket_policy_attachment" {
#   role       = "arn:aws:iam::583625886946:role/AWSReservedSSO_AWSAdministratorAccess_c30ca6b6ac210f51/whibbard@genies.com"
#   policy_arn = aws_iam_policy.bucket_policy.arn
# }

# resource "aws_iam_role_policy_attachment" "deployer_policy_attachment" {
#   role       = "arn:aws:iam::583625886946:role/genies_deployer-role"
#   policy_arn = aws_iam_policy.bucket_policy.arn
# }


resource "aws_iam_policy" "iam_policy_for_lambda" {
 
 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogGroup",
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_exec_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}



data "archive_file" "zip_the_python_code" {
type        = "zip"
source_dir  = "${path.module}/lambda/"
output_path = "${path.module}/trigger_job.zip"
}