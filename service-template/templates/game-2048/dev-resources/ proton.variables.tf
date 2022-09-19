variable "environment" {
  type = object({
    outputs = map(string)
  })
  default = null
}

variable "service" {
  type = object({
    inputs = map(string)
  })
  default = null
}

variable "service_instance" {
  type = object({
    inputs = map(string)
  })
  default = null
}
