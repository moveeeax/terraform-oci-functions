# Requires Terraform >= 1.7 / OpenTofu >= 1.7 for `mock_provider`.
# The module itself still supports >= 1.5 — this requirement is test-only.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  display_name   = "unit-test-fn-app"
  subnet_ids     = ["ocid1.subnet.oc1.phx.aaaaaaaaexamplesubnet"]
}

run "defaults_are_conservative" {
  command = apply

  assert {
    condition     = oci_functions_application.this.shape == "GENERIC_X86"
    error_message = "Default shape should be GENERIC_X86."
  }

  assert {
    condition     = length(oci_functions_application.this.subnet_ids) == 1
    error_message = "Application should be attached to exactly the subnets it was given."
  }

  assert {
    condition     = length(oci_functions_application.this.image_policy_config) == 0
    error_message = "image_policy_config must not be emitted when the caller did not ask for it."
  }

  assert {
    condition     = length(oci_functions_application.this.trace_config) == 0
    error_message = "trace_config must not be emitted when the caller did not ask for it."
  }

  assert {
    condition     = oci_functions_application.this.display_name == "unit-test-fn-app"
    error_message = "display_name must be passed through to the application."
  }

  assert {
    condition     = length(oci_logging_log.invoke) == 0
    error_message = "No invocation log may be created unless invoke_log is set."
  }

  assert {
    condition     = output.invoke_log_id == null
    error_message = "invoke_log_id must be null when invoke_log is not set."
  }
}

run "invoke_log_is_attached_to_the_application" {
  command = apply

  variables {
    display_name = "unit test fn-app"

    invoke_log = {
      log_group_id = "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
    }
  }

  assert {
    condition     = length(oci_logging_log.invoke) == 1
    error_message = "Setting invoke_log must create exactly one log."
  }

  assert {
    condition     = oci_logging_log.invoke[0].log_type == "SERVICE"
    error_message = "The invocation log must be a SERVICE log."
  }

  assert {
    condition     = one(one(oci_logging_log.invoke[0].configuration).source).service == "functions"
    error_message = "The invocation log source must be the functions service."
  }

  assert {
    condition     = one(one(oci_logging_log.invoke[0].configuration).source).category == "invoke"
    error_message = "The invocation log category must be invoke."
  }

  assert {
    condition     = one(one(oci_logging_log.invoke[0].configuration).source).resource == oci_functions_application.this.id
    error_message = "The invocation log must point at this application."
  }

  assert {
    condition     = one(oci_logging_log.invoke[0].configuration).compartment_id == var.compartment_id
    error_message = "The log source compartment must be the application's compartment."
  }

  assert {
    condition     = oci_logging_log.invoke[0].log_group_id == "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
    error_message = "log_group_id must be passed through."
  }

  assert {
    condition     = oci_logging_log.invoke[0].retention_duration == 30
    error_message = "Retention should default to 30 days."
  }

  assert {
    condition     = oci_logging_log.invoke[0].is_enabled == true
    error_message = "The invocation log should default to enabled."
  }

  assert {
    condition     = oci_logging_log.invoke[0].display_name == "unit_test_fn-app_invoke"
    error_message = "The default log name must be the sanitised application name plus _invoke."
  }

  assert {
    condition     = output.invoke_log_id == oci_logging_log.invoke[0].id
    error_message = "invoke_log_id must expose the log OCID."
  }
}

run "invoke_log_overrides_are_passed_through" {
  command = apply

  variables {
    invoke_log = {
      log_group_id   = "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
      display_name   = "fn-invocations"
      retention_days = 90
      is_enabled     = false
    }
  }

  assert {
    condition     = oci_logging_log.invoke[0].display_name == "fn-invocations"
    error_message = "invoke_log.display_name must override the default name."
  }

  assert {
    condition     = oci_logging_log.invoke[0].retention_duration == 90
    error_message = "invoke_log.retention_days must be passed through."
  }

  assert {
    condition     = oci_logging_log.invoke[0].is_enabled == false
    error_message = "invoke_log.is_enabled must be passed through."
  }
}

run "optional_features_are_reachable" {
  command = apply

  variables {
    network_security_group_ids = ["ocid1.networksecuritygroup.oc1.phx.aaaaaaaaexamplensg"]
    syslog_url                 = "tcp+tls://logs.example.com:6514"

    trace_config = {
      domain_id = "ocid1.apmdomain.oc1.phx.aaaaaaaaexampledomain"
    }

    image_policy_config = {
      kms_key_ids = ["ocid1.key.oc1.phx.aaaaaaaaexamplekey"]
    }
  }

  assert {
    condition     = one(oci_functions_application.this.trace_config).is_enabled == true
    error_message = "Tracing should default to enabled once a trace_config is supplied."
  }

  assert {
    condition     = one(oci_functions_application.this.trace_config).domain_id == "ocid1.apmdomain.oc1.phx.aaaaaaaaexampledomain"
    error_message = "APM domain OCID must be passed through to trace_config."
  }

  assert {
    condition     = one(oci_functions_application.this.image_policy_config).is_policy_enabled == true
    error_message = "Image signature verification should default to enabled once an image_policy_config is supplied."
  }

  assert {
    condition     = length(one(oci_functions_application.this.image_policy_config).key_details) == 1
    error_message = "Each KMS key OCID must become one key_details block."
  }

  assert {
    condition     = one(one(oci_functions_application.this.image_policy_config).key_details).kms_key_id == "ocid1.key.oc1.phx.aaaaaaaaexamplekey"
    error_message = "KMS key OCID must be passed through to key_details."
  }

  assert {
    condition     = oci_functions_application.this.syslog_url == "tcp+tls://logs.example.com:6514"
    error_message = "syslog_url must be passed through to the application."
  }

  assert {
    condition     = length(oci_functions_application.this.network_security_group_ids) == 1
    error_message = "network_security_group_ids must be passed through to the application."
  }
}

run "rejects_non_compartment_ocid" {
  command = plan

  variables {
    compartment_id = "my-compartment"
  }

  expect_failures = [var.compartment_id]
}

run "rejects_non_subnet_ocid" {
  command = plan

  variables {
    subnet_ids = ["ocid1.vcn.oc1.phx.aaaaaaaaexamplevcn"]
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_too_many_subnets" {
  command = plan

  variables {
    subnet_ids = [
      "ocid1.subnet.oc1.phx.aaaaaaaaexamplesubnet1",
      "ocid1.subnet.oc1.phx.aaaaaaaaexamplesubnet2",
      "ocid1.subnet.oc1.phx.aaaaaaaaexamplesubnet3",
      "ocid1.subnet.oc1.phx.aaaaaaaaexamplesubnet4",
    ]
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_invalid_shape" {
  command = plan

  variables {
    shape = "GENERIC_RISCV"
  }

  expect_failures = [var.shape]
}

run "rejects_non_nsg_ocid" {
  command = plan

  variables {
    network_security_group_ids = ["ocid1.securitylist.oc1.phx.aaaaaaaaexamplesl"]
  }

  expect_failures = [var.network_security_group_ids]
}

run "rejects_syslog_url_without_supported_scheme" {
  command = plan

  variables {
    syslog_url = "logs.example.com:6514"
  }

  expect_failures = [var.syslog_url]
}

run "rejects_non_apm_domain_ocid" {
  command = plan

  variables {
    trace_config = {
      domain_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
    }
  }

  expect_failures = [var.trace_config]
}

run "rejects_enabled_image_policy_without_keys" {
  command = plan

  variables {
    image_policy_config = {
      is_policy_enabled = true
      kms_key_ids       = []
    }
  }

  expect_failures = [var.image_policy_config]
}

run "rejects_non_kms_key_ocid" {
  command = plan

  variables {
    image_policy_config = {
      kms_key_ids = ["ocid1.vault.oc1.phx.aaaaaaaaexamplevault"]
    }
  }

  expect_failures = [var.image_policy_config]
}

run "rejects_non_log_group_ocid_for_invoke_log" {
  command = plan

  variables {
    invoke_log = {
      log_group_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
    }
  }

  expect_failures = [var.invoke_log]
}

run "rejects_invoke_log_retention_outside_30_day_steps" {
  command = plan

  variables {
    invoke_log = {
      log_group_id   = "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
      retention_days = 45
    }
  }

  expect_failures = [var.invoke_log]
}

run "rejects_blank_invoke_log_name" {
  command = plan

  variables {
    invoke_log = {
      log_group_id = "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
      display_name = "  "
    }
  }

  expect_failures = [var.invoke_log]
}
