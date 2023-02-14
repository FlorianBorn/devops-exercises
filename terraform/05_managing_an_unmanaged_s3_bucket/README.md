## dieser Befehl wird benötigt, wenn man das tf.state file im S3 Buket speichern will
terraform init -backend-config="access_key=AKIAZQWIAASQINXYSBUU" -backend-config="secret_key=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"

terraform import aws_s3_bucket.foobarbucket foobarbucket-1246