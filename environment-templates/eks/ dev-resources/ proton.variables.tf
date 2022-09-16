 variable "environment" {
  type = object({
    inputs = map(string)
    name   = string
  })
  default = null
}