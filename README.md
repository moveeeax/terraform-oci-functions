# terraform-oci-functions

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
Functions application, the logical container for serverless functions. It sets the
subnets the functions run in, the processor shape, application-wide configuration,
network security groups, log forwarding, distributed tracing and image signature
verification.

## Usage

```hcl
module "functions_app" {
  source = "github.com/moveeeax/terraform-oci-functions"

  compartment_id = var.compartment_id
  display_name   = "prod-fn-app"

  # Private subnet: functions reach OCI services through a service or NAT gateway.
  subnet_ids                 = [var.private_subnet_id]
  network_security_group_ids = [var.nsg_id]
  shape                      = "GENERIC_X86"

  # Only run function images signed by this KMS key.
  image_policy_config = {
    kms_key_ids = [var.image_signing_key_id]
  }

  # Ship function logs to a collector over TLS.
  syslog_url = "tcp+tls://logs.example.com:6514"

  # Emit traces to an APM domain.
  trace_config = {
    domain_id = var.apm_domain_id
  }

  config = {
    LOG_LEVEL = "info"
  }

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Security notes

- **Subnets.** OCI decides whether functions get a public address from the subnet
  they run in; the module cannot infer that from an OCID. Pass private subnets
  unless the functions genuinely need to be publicly addressable, and give the VCN
  a service or NAT gateway for egress.
- **`config` is sensitive.** Application config is injected into every function as
  environment variables and routinely carries credentials, so the variable is
  marked `sensitive`. Prefer storing OCI Vault secret OCIDs here and resolving them
  at runtime over embedding literal secrets.
- **Image signature verification** is off unless `image_policy_config` is set. When
  set it defaults to enabled and requires at least one KMS key OCID.
- **Log forwarding and tracing** are off unless `syslog_url` / `trace_config` are
  set. Use the `tcp+tls://` syslog scheme so logs are encrypted in transit.
- Function-level settings (image, image digest, memory and timeout bounds) belong
  to `oci_functions_function`, which this module does not manage.

## Testing

```sh
terraform test
```

The suite in [`tests/`](tests) uses a mocked OCI provider, so it needs no
credentials and no network. `mock_provider` requires Terraform/OpenTofu >= 1.7;
the module itself still supports >= 1.5.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name                         | Description                                                                                      | Type           | Default         | Required |
|------------------------------|--------------------------------------------------------------------------------------------------|----------------|-----------------|:--------:|
| `compartment_id`             | OCID of the compartment in which to create the application. Must be an `ocid1.compartment`/`ocid1.tenancy` OCID. | `string`       | n/a             |   yes    |
| `display_name`               | Human-readable name for the functions application (1-255 characters).                            | `string`       | n/a             |   yes    |
| `subnet_ids`                 | Subnet OCIDs the functions run in (1-3). Each must be an `ocid1.subnet` OCID.                     | `list(string)` | n/a             |   yes    |
| `network_security_group_ids` | NSG OCIDs attached to the application. Empty means the subnets' security lists alone apply.       | `list(string)` | `[]`            |    no    |
| `shape`                      | Processor shape for functions.                                                                   | `string`       | `"GENERIC_X86"` |    no    |
| `config`                     | Application-wide config exposed to functions as env vars. **Sensitive.**                          | `map(string)`  | `{}`            |    no    |
| `syslog_url`                 | Syslog endpoint for function logs (`tcp://`, `udp://` or `tcp+tls://`). Null disables forwarding. | `string`       | `null`          |    no    |
| `trace_config`               | APM tracing: `{ domain_id, is_enabled = true }`. Null disables tracing.                          | `object`       | `null`          |    no    |
| `image_policy_config`        | Image signature verification: `{ is_policy_enabled = true, kms_key_ids = [] }`. Null disables it. | `object`       | `null`          |    no    |
| `freeform_tags`              | Free-form tags applied to the application.                                                       | `map(string)`  | `{}`            |    no    |
| `defined_tags`               | Defined tags applied to the application, keyed `namespace.key`.                                  | `map(string)`  | `{}`            |    no    |

## Outputs

| Name           | Description                                    |
|----------------|------------------------------------------------|
| `id`           | OCID of the functions application.             |
| `display_name` | Display name of the functions application.     |
| `shape`        | Processor shape for functions.                 |
| `state`        | Lifecycle state of the functions application.  |

## License

[MIT](LICENSE)
