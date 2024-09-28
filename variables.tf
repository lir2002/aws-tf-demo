variable "web_certificate_arn" {
    type = string
    description = "Arn to the self-signed web certificate imported prior to the deployment"
}

variable "db_user" {
    description = "User name to create in Database"
    type = string
}

variable "db_pass" {
    description = "User's password in Database"
    type = string
    sensitive = true  
}