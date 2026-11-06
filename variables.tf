variable "compartment_id" {
  description = "OCID of the compartment in which to create the functions application."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment... or ocid1.tenancy...)."
  }
}

variable "display_name" {
  description = "Human-readable name for the functions application."
  type        = string

  validation {
    condition     = length(var.display_name) > 0 && length(var.display_name) <= 255
    error_message = "display_name must be between 1 and 255 characters."
  }
}

variable "subnet_ids" {
  description = "List of subnet OCIDs the application's functions run in. Use private subnets unless the functions genuinely need a public address; egress to OCI services should go through a service gateway or NAT gateway."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0 && length(var.subnet_ids) <= 3
    error_message = "Provide between 1 and 3 subnet OCIDs."
  }

  validation {
    condition     = alltrue([for s in var.subnet_ids : can(regex("^ocid1\\.subnet\\.", s))])
    error_message = "Every entry in subnet_ids must be a subnet OCID (ocid1.subnet...)."
  }
}

variable "network_security_group_ids" {
  description = "OCIDs of network security groups attached to the application. When empty, the subnets' security lists alone govern function traffic."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for n in var.network_security_group_ids : can(regex("^ocid1\\.networksecuritygroup\\.", n))])
    error_message = "Every entry in network_security_group_ids must be a network security group OCID (ocid1.networksecuritygroup...)."
  }
}

variable "shape" {
  description = "Processor shape for functions in the application (GENERIC_X86, GENERIC_ARM, or GENERIC_X86_ARM)."
  type        = string
  default     = "GENERIC_X86"

  validation {
    condition     = contains(["GENERIC_X86", "GENERIC_ARM", "GENERIC_X86_ARM"], var.shape)
    error_message = "shape must be GENERIC_X86, GENERIC_ARM, or GENERIC_X86_ARM."
  }
}

variable "config" {
  description = "Application-wide configuration passed to functions as environment variables. Marked sensitive because these values routinely carry credentials; prefer OCI Vault secret OCIDs over literal secrets here."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "syslog_url" {
  description = "Syslog endpoint that function logs are forwarded to, e.g. \"tcp+tls://logs.example.com:6514\". Null (the default) leaves log forwarding off. Prefer tcp+tls:// so logs are encrypted in transit."
  type        = string
  default     = null

  validation {
    condition     = var.syslog_url == null || can(regex("^(tcp|udp|tcp\\+tls)://[^ ]+$", var.syslog_url))
    error_message = "syslog_url must start with tcp://, udp:// or tcp+tls:// and contain no spaces."
  }
}

variable "trace_config" {
  description = "APM distributed tracing configuration. Null (the default) leaves tracing off."
  type = object({
    domain_id  = string
    is_enabled = optional(bool, true)
  })
  default = null

  validation {
    condition     = var.trace_config == null || can(regex("^ocid1\\.apmdomain\\.", try(var.trace_config.domain_id, "")))
    error_message = "trace_config.domain_id must be an APM domain OCID (ocid1.apmdomain...)."
  }
}

variable "image_policy_config" {
  description = "Image signature verification policy. When enabled, only function images signed by one of the listed KMS keys may be deployed. Null (the default) leaves signature verification off."
  type = object({
    is_policy_enabled = optional(bool, true)
    kms_key_ids       = optional(list(string), [])
  })
  default = null

  validation {
    condition = alltrue([
      for k in try(var.image_policy_config.kms_key_ids, []) : can(regex("^ocid1\\.key\\.", k))
    ])
    error_message = "Every entry in image_policy_config.kms_key_ids must be a KMS key OCID (ocid1.key...)."
  }

  validation {
    condition     = !try(var.image_policy_config.is_policy_enabled, false) || length(try(var.image_policy_config.kms_key_ids, [])) > 0
    error_message = "image_policy_config.kms_key_ids must list at least one KMS key OCID when is_policy_enabled is true."
  }
}

variable "invoke_log" {
  description = "Function invocation log (OCI Logging service log, service \"functions\", category \"invoke\") in an existing log group. Null (the default) creates no log. display_name defaults to \"<display_name>_invoke\", the name the OCI Console proposes; retention_days must be 30, 60, 90, 120, 150 or 180."
  type = object({
    log_group_id   = string
    display_name   = optional(string)
    retention_days = optional(number, 30)
    is_enabled     = optional(bool, true)
  })
  default = null

  validation {
    condition     = var.invoke_log == null || can(regex("^ocid1\\.loggroup\\.", try(var.invoke_log.log_group_id, "")))
    error_message = "invoke_log.log_group_id must be a log group OCID (ocid1.loggroup...)."
  }

  validation {
    condition     = var.invoke_log == null || contains([30, 60, 90, 120, 150, 180], try(var.invoke_log.retention_days, 0))
    error_message = "invoke_log.retention_days must be one of 30, 60, 90, 120, 150 or 180. OCI accepts retention only in 30-day increments up to 180 days and rejects anything else at apply time."
  }

  validation {
    condition     = var.invoke_log == null || try(var.invoke_log.display_name, null) == null || try(length(trimspace(var.invoke_log.display_name)) > 0, false)
    error_message = "invoke_log.display_name must not be blank; leave it null to use \"<display_name>_invoke\"."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the functions application."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the functions application, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
