variable "region" {}
variable "bucket_name" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {}
}
provider "aws" {
  region = var.region
}

resource "aws_iot_policy" "pubsub" {
  name = "PubSubToAnyTopic"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iot:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iot_topic_rule" "sample_iot_topic_rule" {
  name        = var.sample_iot_topic_rule.name
  enabled     = true
  sql         = "SELECT * FROM '${var.sample_iot_topic_rule.topic}'"
  sql_version = "2016-03-23"

  firehose {
    delivery_stream_name = ""
    separator            = "\n"
    role_arn             = aws_lambda_function.test_lambda.arn
  }

  # TODO require?
  error_action {
    cloudwatch_logs {
      log_group_name = ""
      role_arn       = aws_lambda_function.test_lambda.arn
    }
  }
}

resource "aws_lambda_permission" "sample_iot_topic_rule_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.sample_iot_topic_rule.arn
}


resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "aws-waf-logs-terraform-kinesis-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn

    prefix = "WAFLOG/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "ERRORLOG/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    buffer_size = 128

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_table.aws_glue_catalog_table.database_name
        role_arn      = aws_iam_role.firehose_role.arn
        table_name    = aws_glue_catalog_table.aws_glue_catalog_table.name
        region        = "ap-northeast-1"
      }
    }
  }
}




resource "aws_iam_role" "firehose_role" {
  name = "firehose_test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "firehose_policy" {
  name = "terraform_firehose_policy"
  path = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetTable",
        "glue:GetTableVersion",
        "glue:GetTableVersions"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::tf-waf-test-bucket",
        "arn:aws:s3:::tf-waf-test-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListShards"
      ],
      "Resource": "arn:aws:kinesis:ap-northeast-1:111122223333:stream/aws-waf-logs-terraform-kinesis-firehose"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": [
        "arn:aws:kms:ap-northeast-1:111122223333:key/%SSE_KEY_ID%"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.ap-northeast-1.amazonaws.com"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:s3:arn": "arn:aws:s3:::tf-waf-test-bucket/prefix*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:ap-northeast-1:111122223333:log-group:log-group-name:log-stream:log-stream-name"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration"
      ],
      "Resource": [
        "arn:aws:lambda:ap-northeast-1:111122223333:function:%FIREHOSE_DEFAULT_FUNCTION%:%FIREHOSE_DEFAULT_VERSION%""
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "firehose_iam" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}
