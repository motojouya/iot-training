import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
// import * as sqs from 'aws-cdk-lib/aws-sqs';

export class InputStreamStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here

    // example resource
    // const queue = new sqs.Queue(this, 'InputStreamQueue', {
    //   visibilityTimeout: cdk.Duration.seconds(300)
    // });
  }
}

from aws_cdk import (
    Stack,
    aws_iam as iam,
    aws_iot as iot,
    aws_lambda as lambda_,
)
from constructs import Construct


class CdkIotStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # 今回は簡単のため、証明書をCLIで作成している
        cert_arn = 'xxxxxxxxx'

        region = 'ap-northeast-1'
        account_id = 'xxxxxxxxx'

        topic_name = 'test/topic'

        # モノ
        # https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_iot/CfnThing.html
        thing = iot.CfnThing(
            self,
            'MyThing',
            thing_name='my-first-thing',
        )

        # モノと証明書の紐づけ
        # https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_iot/CfnThingPrincipalAttachment.html
        thing_principal_attachment = iot.CfnThingPrincipalAttachment(
            self,
            'AttachCertificateToMyThing',
            principal=cert_arn,
            thing_name=thing.thing_name,
        )

        # ポリシー
        # https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_iot/CfnPolicy.html
        # https://docs.aws.amazon.com/ja_jp/iot/latest/developerguide/pub-sub-policy.html
        policy = iot.CfnPolicy(
            self,
            'IotPolicy',
            policy_document={
                "Version":"2012-10-17",
				"Statement":[
					{
						"Effect":"Allow",
						"Action":[
							"iot:Connect"
						],
						"Resource":[
							f"arn:aws:iot:{region}:{account_id}:client/*"
						]
					},
					{
						"Effect": "Allow",
						"Action": [
							"iot:Publish",
							"iot:Receive"
						],
						"Resource": [
							f"arn:aws:iot:{region}:{account_id}:topic/{topic_name}"
						]
				    },
					{
						"Effect": "Allow",
						"Action": [
							"iot:Subscribe"
						],
						"Resource": [
							f"arn:aws:iot:{region}:{account_id}:topicfilter/{topic_name}"
						]
				    }
				]
            },
			policy_name='iot-policy',
        )

        # ポリシーと証明書の紐づけ
        # https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_iot/CfnPolicyPrincipalAttachment.html
        policy_principal_attachment = iot.CfnPolicyPrincipalAttachment(
            self,
            'AttachCertificateToPolicy',
            policy_name=policy.policy_name,
            principal=cert_arn,
        )

        # 依存関係の挿入
        thing_principal_attachment.add_dependency(thing)
        policy_principal_attachment.add_dependency(policy)

        # Test lambda function
        test_function = lambda_.Function(
            self,
            'TestFunction',
            code=lambda_.Code.from_inline(
                code='def lambda_handler(event, context): print(f"Event: {event}\nContext: {context}", )',
            ),
            handler='index.lambda_handler',
            runtime=lambda_.Runtime.PYTHON_3_10,
            function_name='test-function-iot-core'
        )

        # Topic Rule
        topic_rule = iot.CfnTopicRule(
            self,
            'TopicRule',
            topic_rule_payload=iot.CfnTopicRule.TopicRulePayloadProperty(
                actions=[
                    iot.CfnTopicRule.ActionProperty(
                        lambda_=iot.CfnTopicRule.LambdaActionProperty(
                            function_arn=test_function.function_arn,
                        ),
                    )
                ],
                sql=f"SELECT * FROM '{topic_name}'",
                aws_iot_sql_version='2016-03-23',
            ),
            rule_name='test_topic_rule',
        )

        # add lambda trigger
        test_function.add_permission(
            'AddIotTopicRuleTrigger',
            principal=iam.ServicePrincipal(service='iot.amazonaws.com'),
            source_arn=topic_rule.attr_arn,
        )

