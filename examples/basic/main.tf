provider "oci" {}

module "functions_app" {
  source = "../.."

  compartment_id = var.compartment_id
  display_name   = "example-fn-app"
  subnet_ids     = [var.subnet_id]
  shape          = "GENERIC_X86"

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
  description = "OCID of the subnet the example functions run in."
  type        = string
}

output "functions_application_id" {
  value = module.functions_app.id
}
