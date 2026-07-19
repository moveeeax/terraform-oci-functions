# terraform-oci-functions

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
Functions application, the logical container for serverless functions. It sets the
subnets the functions run in, the processor shape and application-wide configuration.

## Usage

```hcl
module "functions_app" {
  source = "github.com/moveeeax/terraform-oci-functions"

  compartment_id = var.compartment_id
  display_name   = "prod-fn-app"
  subnet_ids     = [var.subnet_id]
  shape          = "GENERIC_X86"

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

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name             | Description                                                          | Type           | Default         | Required |
|------------------|----------------------------------------------------------------------|----------------|-----------------|:--------:|
| `compartment_id` | OCID of the compartment in which to create the application.          | `string`       | n/a             |   yes    |
| `display_name`   | Human-readable name for the functions application.                   | `string`       | n/a             |   yes    |
| `subnet_ids`     | Subnet OCIDs the functions run in (1-3).                             | `list(string)` | n/a             |   yes    |
| `shape`          | Processor shape for functions.                                       | `string`       | `"GENERIC_X86"` |    no    |
| `config`         | Application-wide config exposed to functions as env vars.            | `map(string)`  | `{}`            |    no    |
| `freeform_tags`  | Free-form tags applied to the application.                           | `map(string)`  | `{}`            |    no    |
| `defined_tags`   | Defined tags applied to the application, keyed `namespace.key`.      | `map(string)`  | `{}`            |    no    |

## Outputs

| Name           | Description                                    |
|----------------|------------------------------------------------|
| `id`           | OCID of the functions application.             |
| `display_name` | Display name of the functions application.     |
| `shape`        | Processor shape for functions.                 |
| `state`        | Lifecycle state of the functions application.  |

## License

[MIT](LICENSE)
