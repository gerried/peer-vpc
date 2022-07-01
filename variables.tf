
variable "env" {
    description = "various env"
    type = map(any)
    default = {
      prod = "524913668773"
    }
}

variable "accepter_account_id" {
  type =  string
  default = "883250726777"
}

variable "aws_region" {
  default = "us-east-1"
}