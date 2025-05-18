variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "image_uri" {
  description = "ECR image URI for the Flask app"
  type        = string
}

variable "db_username" {
  type    = string
  default = "flaskuser"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "flaskdb"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
