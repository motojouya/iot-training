resource "aws_s3_bucket" "athena_query_cache" {
  bucket = var.athena_bucket_name
}

resource "aws_athena_workgroup" "general_work_group" {
  name          = var.general_work_group_name
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false
    result_configuration {
      output_location = "s3://${var.athena_bucket_name}/query-result/"
    }
  }
}
