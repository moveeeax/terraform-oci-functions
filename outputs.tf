output "id" {
  description = "OCID of the functions application."
  value       = oci_functions_application.this.id
}

output "display_name" {
  description = "Display name of the functions application."
  value       = oci_functions_application.this.display_name
}

output "shape" {
  description = "Processor shape for functions in the application."
  value       = oci_functions_application.this.shape
}

output "state" {
  description = "Lifecycle state of the functions application."
  value       = oci_functions_application.this.state
}

output "invoke_log_id" {
  description = "OCID of the function invocation log; null when invoke_log is not set."
  value       = one(oci_logging_log.invoke[*].id)
}
