Benötigte Permission für die Lambda Rolle:
Recht für Listing Lambda Policies benötigt
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "lambda:ListFunctions",
            "Resource": "*"
        },


# Create the infrastructure
terraform init

export AWS_ACCESS_KEY_ID="<access-key-id>"
export AWS_SECRET_ACCESS_KEY="<secret-access-key>"
terraform apply -auto-approve 

# Links
Passing Env Vars for Provider Secrets: https://registry.terraform.io/providers/hashicorp/aws/2.42.0/docs#authentication 