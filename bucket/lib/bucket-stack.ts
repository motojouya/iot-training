import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
// import * as sqs from 'aws-cdk-lib/aws-sqs';

export class BucketStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);
    new s3.Bucket(this, 'IotBucket', { bucketName: 'motojouya-data' });
    // The code that defines your stack goes here

    // example resource
    // const queue = new sqs.Queue(this, 'BucketQueue', {
    //   visibilityTimeout: cdk.Duration.seconds(300)
    // });
  }
}
