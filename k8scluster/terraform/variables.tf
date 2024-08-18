variable "new_user" {
  type    = string
  default = "meta.txt"
}
variable "VAULT_TOKEN" {
  type        = string
  description = "Vault token for accessing secrets"
  default     = ""
}
variable "vault_host" {
  type        = string
  description = "Vault host"
  default     = ""
}
# cloud_id  = "b1gqkugmt2d5nr2n85l9"
# folder_id = "b1g3acl1dihgarklvhm3"
# zone      = "ru-central1-a"

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
