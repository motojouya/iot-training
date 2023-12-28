import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
// import * as sqs from 'aws-cdk-lib/aws-sqs';

export class GlueStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here

    // example resource
    // const queue = new sqs.Queue(this, 'GlueQueue', {
    //   visibilityTimeout: cdk.Duration.seconds(300)
    // });
  }
}

import { Construct } from 'constructs';
import {
  aws_s3,
  aws_athena,
  Stack,
  StackProps,
  RemovalPolicy,
  aws_glue,
} from 'aws-cdk-lib';
import * as glue_alpha from '@aws-cdk/aws-glue-alpha';

export class ProcessStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps) {
    super(scope, id, props);

    // データ格納バケット
    const dataBucket = new aws_s3.Bucket(this, 'dataBucket', {
      bucketName: `data-${this.account}-${this.region}`,
      removalPolicy: RemovalPolicy.DESTROY,
    });

    // Athenaクエリ結果格納バケット
    const athenaQueryResultBucket = new aws_s3.Bucket(
      this,
      'athenaQueryResultBucket',
      {
        bucketName: `athena-query-result-${this.account}`,
        removalPolicy: RemovalPolicy.DESTROY,
      }
    );

    // データカタログ
    const dataCatalog = new glue_alpha.Database(this, 'dataCatalog', {
      databaseName: 'data_catalog',
    });

    // データカタログテーブル
    const dataGlueTable = new glue_alpha.Table(this, 'sourceDataGlueTable', {
      tableName: 'source_data_glue_table',
      database: dataCatalog,
      bucket: dataBucket,
      s3Prefix: 'data/',
      partitionKeys: [
        {
          name: 'date',
          type: glue_alpha.Schema.STRING,
        },
      ],
      dataFormat: glue_alpha.DataFormat.JSON,
      columns: [
        {
          name: 'userId',
          type: glue_alpha.Schema.STRING,
        },
        {
          name: 'count',
          type: glue_alpha.Schema.FLOAT,
        },
      ],
    });

    // データカタログテーブルへのPartition Projectionの設定
    const cfnTable = dataGlueTable.node.defaultChild as aws_glue.CfnTable;
    cfnTable.addPropertyOverride('TableInput.Parameters', {
      'projection.enabled': true,
      'projection.date.type': 'date',
      'projection.date.range': '2022/06/28,NOW',
      'projection.date.format': 'yyyy/MM/dd',
      'projection.date.interval': 1,
      'projection.date.interval.unit': 'DAYS',
      'storage.location.template':
        `s3://${dataBucket.bucketName}/data/` + '${date}',
    });

    // Athenaワークグループ
    new aws_athena.CfnWorkGroup(this, 'athenaWorkGroup', {
      name: 'athenaWorkGroup',
      workGroupConfiguration: {
        resultConfiguration: {
          outputLocation: `s3://${athenaQueryResultBucket.bucketName}/result-data`,
        },
      },
      recursiveDeleteOption: true,
    });
  }
}
