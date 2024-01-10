# policy for things
data "aws_iam_policy_document" "things_policy_doc" {
  statement {
    actions = [
      "iot:Connect",
    ]
    resources = [
      "arn:aws:iot:ap-northeast-1:${var.account_id}:client/&{iot:Connection.Thing.ThingName}",
    ]
  }

  statement {
    actions = [
      "iot:Publish",
    ]
    resources = [
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/data/&{iot:Connection.Thing.ThingName}",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get"
    ]
  }

  statement {
    actions = [
      "iot:Receive",
    ]
    resources = [
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/delta",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/accepted",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/rejected",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get/accepted",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get/rejected"
    ]
  }

  statement {
    actions = [
      "iot:Subscribe",
    ]
    resources = [
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/delta",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/accepted",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/rejected",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get/accepted",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get/rejected"
    ]
  }
}

resource "aws_iam_policy" "things_policy" {
  name   = "iot_things_policy"
  policy = data.aws_iam_policy_document.things_policy_doc.json
}

# rule topic
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

