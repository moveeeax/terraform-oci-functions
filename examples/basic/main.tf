provider "oci" {}

module "functions_app" {
  source = "../.."

  compartment_id = var.compartment_id
  display_name   = "example-fn-app"
  subnet_ids     = [var.subnet_id]
  shape          = "GENERIC_X86"

  # Attach the application to an NSG when one is supplied, so function traffic is
  # governed by an explicit rule set rather than the subnet's default security list.
  network_security_group_ids = var.network_security_group_id == null ? [] : [var.network_security_group_id]

  # Forward function logs over TLS when a collector is supplied.
  syslog_url = var.syslog_url

  # Only accept function images signed by the supplied KMS key.
  image_policy_config = var.image_signing_kms_key_id == null ? null : {
    kms_key_ids = [var.image_signing_kms_key_id]
  }

  # Emit traces to an APM domain when one is supplied.
  trace_config = var.apm_domain_id == null ? null : {
    domain_id = var.apm_domain_id
  }

  config = {
    LOG_LEVEL = "info"
  }

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "compartment_id" {
  description = "Compartment OCID to deploy the example application into."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet the example functions run in. Use a private subnet."
  type        = string
}

variable "network_security_group_id" {
  description = "Optional NSG OCID to attach to the example application."
  type        = string
  default     = null
}

variable "syslog_url" {
  description = "Optional syslog endpoint for function logs, e.g. tcp+tls://logs.example.com:6514."
  type        = string
  default     = null
}

variable "image_signing_kms_key_id" {
  description = "Optional KMS key OCID used to verify function image signatures."
  type        = string
  default     = null
}

variable "apm_domain_id" {
  description = "Optional APM domain OCID to send function traces to."
  type        = string
  default     = null
}

output "functions_application_id" {
  value = module.functions_app.id
}
