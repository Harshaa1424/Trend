variable "region" { default = "us-east-2" }
variable "Keypair" { description = "SSH keypair name in AWS" }
variable "public_key_path" { default = "~/.ssh/id_rsa.pub" }
