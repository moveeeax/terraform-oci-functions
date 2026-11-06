resource "oci_functions_application" "this" {
  compartment_id = var.compartment_id
  display_name   = var.display_name
  subnet_ids     = var.subnet_ids
  shape          = var.shape
  config         = var.config

  network_security_group_ids = var.network_security_group_ids
  syslog_url                 = var.syslog_url

  # Distributed tracing to an APM domain. Off unless trace_config is supplied.
  dynamic "trace_config" {
    for_each = var.trace_config == null ? [] : [var.trace_config]

    content {
      domain_id  = trace_config.value.domain_id
      is_enabled = trace_config.value.is_enabled
    }
  }

  # Image signature verification. When enabled, OCI refuses to deploy a function
  # image that is not signed by one of the referenced KMS keys.
  dynamic "image_policy_config" {
    for_each = var.image_policy_config == null ? [] : [var.image_policy_config]

    content {
      is_policy_enabled = image_policy_config.value.is_policy_enabled

      dynamic "key_details" {
        for_each = image_policy_config.value.kms_key_ids

        content {
          kms_key_id = key_details.value
        }
      }
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Function invocation logs. OCI models them as a Logging service log whose
# source is the application (service "functions", category "invoke"); without
# one, function stdout/stderr is dropped unless syslog_url forwards it.
resource "oci_logging_log" "invoke" {
  count = var.invoke_log == null ? 0 : 1

  display_name       = coalesce(var.invoke_log.display_name, "${replace(var.display_name, "/[^A-Za-z0-9_-]/", "_")}_invoke")
  log_group_id       = var.invoke_log.log_group_id
  log_type           = "SERVICE"
  is_enabled         = var.invoke_log.is_enabled
  retention_duration = var.invoke_log.retention_days

  configuration {
    compartment_id = var.compartment_id

    source {
      category    = "invoke"
      resource    = oci_functions_application.this.id
      service     = "functions"
      source_type = "OCISERVICE"
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
