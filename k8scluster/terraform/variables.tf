variable "new_user" {
  type    = string
  default = "meta.txt"
}
#set the value as environment variable: export VAULT_TOKEN=value
variable "VAULT_TOKEN" {
  type        = string
  description = "Vault token for accessing secrets"
  default     = ""

#set the value as environment variable: export vault_host=<IP:8200>
}
variable "vault_host" {
  type        = string
  description = "Vault host"
  default     = ""
}

variable "cloud_id" {
  type        = string
  description = "YC id"
  default     = "b1gqkugmt2d5nr2n85l9"
 }

 variable "folder_id" {
  type        = string
  description = "YC folder id"
  default     = "b1g3acl1dihgarklvhm3"
 }

 variable "zone" {
  type        = string
  description = "YC zone"
  default     = "ru-central1-a"
 }
