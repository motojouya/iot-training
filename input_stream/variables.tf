# basic
variable "region" {}
variable "account_id" {}

# storage
variable "bucket_arn" {}
variable "glue_catalog_database_name" {}
variable "glue_catalog_table_name" {}

# stream
variable "topic_rule" {}
variable "iot_topic" {}
variable "error_log" {} # motojouya/iot/logs
variable "firehose_name" {}
