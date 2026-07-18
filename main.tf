resource "oci_functions_application" "this" {
  compartment_id = var.compartment_id
  display_name   = var.display_name
  subnet_ids     = var.subnet_ids
  shape          = var.shape
  config         = var.config

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
