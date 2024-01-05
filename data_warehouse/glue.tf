
variable "glue_catalog_database_name" {}
variable "glue_catalog_table_name" {}
variable "date_range_start" {}
variable "data_bucket_name" {}
variable "data_prefix" {} # /home/air



resource "aws_glue_catalog_database" "home_air_database" {
  name = var.glue_catalog_database_name
}

resource "aws_glue_catalog_table" "home_air_table" {
  database_name = aws_glue_catalog_database.iot_database.name
  name          = var.glue_catalog_table_name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "projection.enabled"                 = "true"
    "projection.orderdate.format"        = "yyyy/MM/dd"
    "projection.orderdate.type"          = "date"
    "projection.orderdate.interval"      = "1"
    "projection.orderdate.interval.unit" = "DAYS"
    "projection.orderdate.range"         = "${var.date_range_start},NOW"
    "storage.location.template"          = "s3://${var.data_bucket_name}${var.data_prefix}/$${time}"
  }

  storage_descriptor {
    location      = "s3://${var.data_bucket_name}${var.data_prefix}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"
    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "device"
      type = "string"
    }
    columns {
      name = "time"
      type = "timestamp"
    }
    columns {
      name = "temperature"
      type = "float"
    }
    columns {
      name = "humidity"
      type = "float"
    }
  }

  partition_keys {
    name = "time"
    type = "timestamp"
  }
}
