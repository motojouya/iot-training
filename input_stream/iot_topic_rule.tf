resource "aws_cloudwatch_log_group" "iot_logs" {
  name = var.error_log # motojouya/iot/logs
}

data "aws_iam_policy_document" "iot_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["iot.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iot_role" {
  name               = "iot_role"
  assume_role_policy = data.aws_iam_policy_document.iot_assume_role.json
}

resource "aws_iot_topic_rule" "iot_topic_rule" {
  name        = var.topic_rule
  enabled     = true
  sql         = "SELECT * FROM '${var.iot_topic}'"
  sql_version = "2024-01-01"

  firehose {
    delivery_stream_name = aws_kinesis_firehose_delivery_stream.iot_to_s3_stream.name
    separator            = "\n"
    role_arn             = aws_iam_role.iot_role.arn
  }

  # TODO require?
  error_action {
    cloudwatch_logs {
      log_group_name = aws_cloudwatch_log_group.iot_logs.name
      role_arn       = aws_iam_role.iot_role.arn
    }
  }
}
