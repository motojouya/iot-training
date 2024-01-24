resource "aws_cloudwatch_log_group" "iot_logs" {
  name = var.error_log
}

data "aws_iam_policy_document" "iot_policy_data" {

  statement {
    actions = [
      "logs:GetLogDelivery",
      "logs:ListLogDeliveries",
      "logs:DeleteAccountPolicy",
      "logs:DeleteResourcePolicy",
      "logs:StopLiveTail",
      "logs:CancelExportTask",
      "logs:DeleteLogDelivery",
      "logs:DescribeQueryDefinitions",
      "logs:DescribeResourcePolicies",
      "logs:DescribeDestinations",
      "logs:DescribeQueries",
      "logs:DescribeLogGroups",
      "logs:DescribeAccountPolicies",
      "logs:DescribeDeliverySources",
      "logs:StopQuery",
      "logs:TestMetricFilter",
      "logs:DeleteQueryDefinition",
      "logs:PutQueryDefinition",
      "logs:PutAccountPolicy",
      "logs:DescribeDeliveryDestinations",
      "logs:Link",
      "logs:CreateLogDelivery",
      "logs:PutResourcePolicy",
      "logs:DescribeExportTasks",
      "logs:UpdateLogDelivery",
      "firehose:ListDeliveryStreams",
      "logs:DescribeDeliveries"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "logs:*"
    ]
    resources = [
      "arn:aws:logs:*:${var.account_id}:log-group:",
    ]
  }

  statement {
    actions = [
      "firehose:DescribeDeliveryStream",
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
      "firehose:ListTagsForDeliveryStream",
      "firehose:TagDeliveryStream",
      "firehose:UntagDeliveryStream"
    ]
    resources = [
      "arn:aws:firehose:*:${var.account_id}:deliverystream/*"
    ]
  }
}

resource "aws_iam_policy" "iot_policy" {
  name   = "terraform_iot_policy"
  policy = data.aws_iam_policy_document.iot_policy_data.json
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

resource "aws_iam_role_policy_attachment" "iot_policy_attachment" {
  role       = aws_iam_role.iot_role.name
  policy_arn = aws_iam_policy.iot_policy.arn
}

resource "aws_iot_topic_rule" "iot_topic_rule" {
  name        = var.topic_rule
  enabled     = true
  sql         = "SELECT * FROM '${var.iot_topic}'"
  sql_version = "2016-03-23"

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
