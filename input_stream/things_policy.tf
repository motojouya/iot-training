data "aws_iam_policy_document" "things_policy_doc" {
  statement {
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
  }

  # statement {
  #   actions = [
  #     "iot:Connect",
  #   ]
  #   resources = [
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:client/&{iot:Connection.Thing.ThingName}",
  #   ]
  # }

  # statement {
  #   actions = [
  #     "iot:Publish",
  #   ]
  #   resources = [
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/data/&{iot:Connection.Thing.ThingName}",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get"
  #   ]
  # }

  # statement {
  #   actions = [
  #     "iot:Receive",
  #   ]
  #   resources = [
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/delta",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/accepted",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/rejected",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get/accepted",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topic/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get/rejected"
  #   ]
  # }

  # statement {
  #   actions = [
  #     "iot:Subscribe",
  #   ]
  #   resources = [
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/delta",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/accepted",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/update/rejected",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get/accepted",
  #     "arn:aws:iot:ap-northeast-1:${var.account_id}:topicfilter/$aws/things/&{iot:Connection.Thing.ThingName}/shadow/get/rejected"
  #   ]
  # }
}

resource "aws_iot_policy" "things_policy" {
  name   = "iot_things_policy"
  policy = data.aws_iam_policy_document.things_policy_doc.json
}
