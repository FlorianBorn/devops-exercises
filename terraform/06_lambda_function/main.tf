terraform {
  required_version = "~> 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  #access_key = "***"  # instead, export this as env var: export AWS_ACCESS_KEY_ID="<access-key-id>"
  #secret_key = "***" # instead, export this as env var: export AWS_SECRET_ACCESS_KEY="<secret-access-key>"
}


# https://stackoverflow.com/questions/71992754/how-to-generate-zip-file-for-lambda-via-terrarform
data "archive_file" "eol_lambda_function" {
  type = "zip"
  source_file = "get_lambda_runtime_eol.py"
  output_path = "get_lambda_runtime_eol.zip"
}


resource "aws_lambda_function" "get_lambda_runtime_eol" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = data.archive_file.eol_lambda_function.output_path
  function_name = "get_lambda_runtime_eol"
  role          = aws_iam_role.eol_without_s3.arn
  handler       = "get_lambda_runtime_eol.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.eol_lambda_function.output_base64sha256

  runtime = "python3.9"
  timeout = 30

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_iam_role" "eol_without_s3" {
    name = "role_eol_without_s3"

    tags = {
      "Name" = "my_eol_1"
    }

    assume_role_policy = <<HERE
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}  
HERE
}

resource "aws_iam_policy" "list_lambda_functions" {
    name = "policy_access_eol_status_bucket"

    policy = <<HERE
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:ListFunctions"
            ],
            "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": "*"
        }        
    ]
}
HERE
}


resource "aws_iam_policy_attachment" "allow_list_lambda_functions_to_eol_without_s3" {
    name       = "allow_list_lambda_functions_to_eol_without_s3"
  roles = [ aws_iam_role.eol_without_s3.name ]
  policy_arn = aws_iam_policy.list_lambda_functions.arn
}