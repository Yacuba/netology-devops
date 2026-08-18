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
| [yandex_mdb_mysql_database.db](https://registry.terraform.io/providers/hashicorp/yandex/latest/docs/resources/mdb_mysql_database) | resource |
| [yandex_mdb_mysql_user.user](https://registry.terraform.io/providers/hashicorp/yandex/latest/docs/resources/mdb_mysql_user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | MySQL Cluster ID | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name | `string` | n/a | yes |
| <a name="input_user_name"></a> [user\_name](#input\_user\_name) | Database user name | `string` | n/a | yes |
| <a name="input_user_password"></a> [user\_password](#input\_user\_password) | Database user password | `string` | `"StrongPassword123!"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Created database name |
| <a name="output_user_name"></a> [user\_name](#output\_user\_name) | Created user name |
<!-- END_TF_DOCS -->