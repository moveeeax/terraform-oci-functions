variable "compartment_id" {
  description = "OCID of the compartment in which to create the functions application."
  type        = string
}

variable "display_name" {
  description = "Human-readable name for the functions application."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet OCIDs the application's functions run in."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0 && length(var.subnet_ids) <= 3
    error_message = "Provide between 1 and 3 subnet OCIDs."
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
  description = "Application-wide configuration passed to functions as environment variables."
  type        = map(string)
  default     = {}
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
