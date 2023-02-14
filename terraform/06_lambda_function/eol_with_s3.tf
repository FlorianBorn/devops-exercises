resource "aws_s3_bucket" "eol_status_files" {
    bucket = "bucket-eol-status-file"
    
    tags = {
      "Name" = "bucket-eol-status-file"
    }
}

resource "aws_s3_bucket_policy" "allow_lambda_access" {
  bucket = aws_s3_bucket.eol_status_files.id
  policy = <<HERE
{
    "Version": "2012-10-17",
    "Id": "PutObjReadObj",
    "Statement": [{
        "Sid": "AllowLambdaAccess",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
            "s3:PutObject",
            "s3:GetObject"
        ],
        "Resource": "arn:aws:s3:::${aws_s3_bucket.eol_status_files.bucket}/*"
    },
    {
        "Sid": "AllowLambdaAccess",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
            "s3:ListBucket"
        ],
        "Resource": "arn:aws:s3:::${aws_s3_bucket.eol_status_files.bucket}"
    }]
}
HERE
}



# https://stackoverflow.com/questions/71992754/how-to-generate-zip-file-for-lambda-via-terrarform
data "archive_file" "eol_lambda_s3_function" {
  type = "zip"
  source_file = "get_lambda_runtime_eol_with_s3.py"
  output_path = "get_lambda_runtime_eol_with_s3.zip"
}


resource "aws_lambda_function" "get_lambda_runtime_eol_with_s3" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = data.archive_file.eol_lambda_s3_function.output_path
  function_name = "get_lambda_runtime_eol_with_s3"
  role          = aws_iam_role.eol_with_s3.arn
  handler       = "get_lambda_runtime_eol_with_s3.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = data.archive_file.eol_lambda_s3_function.output_base64sha256

  runtime = "python3.9"
  timeout = 30

  environment {
    variables = {
      foo = "bar"
      destination_bucket = aws_s3_bucket.eol_status_files.bucket
    }
  }
}

resource "aws_iam_role" "eol_with_s3" {
    name = "role_eol_with_s3"

    tags = {
      "Name" = "my_eol_2"
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

resource "aws_iam_policy" "list_lambda_functions2" {
    name = "policy_access_eol_status_bucket2"

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
        }
    ]
}
HERE
}


resource "aws_iam_policy_attachment" "allow_list_lambda_functions_to_eol_with_s3" {
    name       = "allow_list_lambda_functions_to_eol_with_s3"
  roles = [ aws_iam_role.eol_with_s3.name ]
  policy_arn = aws_iam_policy.list_lambda_functions2.arn
}