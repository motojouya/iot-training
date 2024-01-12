data "aws_iam_policy_document" "firehose_policy_data" {
  statement {
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "${var.bucket_arn}",
      "${var.bucket_arn}/*"
    ]
  }
  statement {
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [
      "arn:aws:kinesis:ap-northeast-1:${var.account_id}:stream/${var.firehose_name}"
    ]
  }
  # statement {
  #   actions = [
  #     "kms:Decrypt",
  #     "kms:GenerateDataKey"
  #   ]
  #   resources = [
  #     "arn:aws:kms:ap-northeast-1:111122223333:key/%SSE_KEY_ID%"
  #   ]
  #   "Condition": {
  #     "StringEquals": {
  #       "kms:ViaService": "s3.ap-northeast-1.amazonaws.com"
  #     },
  #     "StringLike": {
  #       "kms:EncryptionContext:aws:s3:arn": "arn:aws:s3:::tf-waf-test-bucket/prefix*"
  #     }
  #   }
  # }
  # statement {
  #   actions = [
  #     "logs:PutLogEvents"
  #   ]
  #   resources = [
  #     "arn:aws:logs:ap-northeast-1:111122223333:log-group:log-group-name:log-stream:log-stream-name"
  #   ]
  # }
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "firehose_policy" {
  name   = "terraform_firehose_policy"
  policy = data.aws_iam_policy_document.firehose_policy_data.json
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_role_policy_attachment" "firehose_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_kinesis_firehose_delivery_stream" "iot_to_s3_stream" {
  name        = var.firehose_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = var.bucket_arn

    buffering_size = 64

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }

      output_format_configuration {
        serializer {
          orc_ser_de {}
        }
      }

      schema_configuration {
        database_name = var.glue_catalog_database_name
        role_arn      = aws_iam_role.firehose_role.arn
        table_name    = var.glue_catalog_table_name
        region        = var.region
      }
    }
  }
}
