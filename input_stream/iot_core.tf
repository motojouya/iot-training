data "aws_iam_policy_document" "example" {
  statement {
    actions = [
      "iot:Connect",
    ]
    resources = [
      "arn:aws:iot:ap-northeast-1:${var.account_id}:client/${${iot:Connection.Thing.ThingName}}",
    ]
  }

  statement {
    actions = [
      "iot:Publish",
    ]
    resources = [
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/data/${${iot:Connection.Thing.ThingName}}",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/update",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/get"
    ]
  }

  statement {
    actions = [
      "iot:Receive",
    ]
    resources = [
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/update/delta",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/update/accepted",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/update/rejected",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/get/accepted",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/get/rejected"
    ]
  }

  statement {
    actions = [
      "iot:Subscribe",
    ]
    resources = [
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/update/delta",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/update/accepted",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/update/rejected",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/get/accepted",
      "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/${${iot:Connection.Thing.ThingName}}/shadow/get/rejected"
    ]
  }
}

resource "aws_iam_policy" "pubsub" {
  name   = "PubSubToAnyTopic"
  policy = data.aws_iam_policy_document.example.json
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

