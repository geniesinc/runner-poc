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