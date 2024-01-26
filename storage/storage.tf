resource "aws_s3_bucket" "iot_bucket" {
  bucket = var.bucket_name
}

resource "aws_glue_catalog_database" "home_air_database" {
  name = var.glue_catalog_database_name
}

resource "aws_glue_catalog_table" "home_air_table" {
  database_name = aws_glue_catalog_database.home_air_database.name
  name          = var.glue_catalog_table_name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "projection.enabled"                = "true"
    "projection.datehour.type"          = "date"
    "projection.datehour.format"        = "yyyy/MM/dd/HH"
    "projection.datehour.range"         = "2021/01/01/00,NOW"
    "projection.datehour.interval"      = "1"
    "projection.datehour.interval.unit" = "HOURS"
    # need change partition for firehose dynamic partioning
    # "storage.location.template"         = "s3://${var.bucket_name}${var.data_prefix}/$${datehour}/"
    "storage.location.template"         = "s3://${var.bucket_name}/$${datehour}/"
    "classification"                    = "orc"
    "compressionType"                   = "gzip"
  }

  storage_descriptor {
    location      = "s3://${var.bucket_name}${var.data_prefix}"
    input_format  = "org.apache.hadoop.hive.ql.io.orc.OrcInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat"
    compressed    = true

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.orc.OrcSerde"
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
      type = "float"
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
    name = "datehour"
    type = "string"
  }
}
