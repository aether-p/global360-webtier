# Variables for project: group location, user name,

variable "resource_group_location" {
  type        = string
  default     = "Australia East"
  description = "Location of the resource group."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}