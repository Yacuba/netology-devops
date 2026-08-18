<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [yandex_mdb_mysql_cluster.cluster](https://registry.terraform.io/providers/hashicorp/yandex/latest/docs/resources/mdb_mysql_cluster) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_HA"></a> [HA](#input\_HA) | High Availability mode (false = 1 host, true = 2 hosts) | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the MySQL cluster | `string` | n/a | yes |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Disk size in GB | `number` | `10` | no |
| <a name="input_disk_type_id"></a> [disk\_type\_id](#input\_disk\_type\_id) | Disk type | `string` | `"network-ssd"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment: PRESTABLE or PRODUCTION | `string` | `"PRESTABLE"` | no |
| <a name="input_hosts"></a> [hosts](#input\_hosts) | List of hosts with zone and subnet\_id | <pre>list(object({<br/>    zone      = string<br/>    subnet_id = string<br/>  }))</pre> | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | VPC Network ID | `string` | n/a | yes |
| <a name="input_resource_preset_id"></a> [resource\_preset\_id](#input\_resource\_preset\_id) | Minimal burstable compute preset | `string` | `"b1.medium"` | no |
| <a name="input_version_mysql"></a> [version\_mysql](#input\_version\_mysql) | MySQL version | `string` | `"8.0"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | MySQL cluster ID |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | MySQL cluster name |
<!-- END_TF_DOCS -->