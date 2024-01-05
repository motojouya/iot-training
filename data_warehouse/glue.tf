
resource "aws_glue_catalog_database" "home_air_database" {
  name = var.glue_catalog_database_name
}

resource "aws_glue_catalog_table" "home_air_table" {
  database_name = aws_glue_catalog_database.home_air_database.name
  name          = var.glue_catalog_table_name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "projection.enabled"            = "true"
    "projection.time.format"        = "yyyy/MM/dd"
    "projection.time.type"          = "date"
    "projection.time.interval"      = "1"
    "projection.time.interval.unit" = "DAYS"
    "projection.time.range"         = "${var.date_range_start},NOW"
    "storage.location.template"     = "s3://${var.data_bucket_name}${var.data_prefix}/$${time}"
    "classification"                = "orc"
  }

  storage_descriptor {
    location      = "s3://${var.data_bucket_name}${var.data_prefix}"
    input_format  = "org.apache.hadoop.hive.ql.io.orc.OrcInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.orc.OrcOutputFormat"
    compressed = true
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
