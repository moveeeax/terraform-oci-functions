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
