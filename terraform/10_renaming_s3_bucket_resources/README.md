1) create 2 buckets manually
    --> wonderbucket124
    --> foobarbucket-1234-tfstate (for storing tfstate)
2) Init terraform with s3 as backend
    terraform init -backend-config="access_key=\<ACCESS-KEy\>" -backend-config="secret_key=\<SECRET-KEY\>"
2) import the buckets state 
3) create a new bucket resource referencing the same bucket
4) delete the old bucket state from terraform
5) import the state to the new ressource