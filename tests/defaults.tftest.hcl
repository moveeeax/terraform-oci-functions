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
