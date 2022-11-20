# Access Key
variable AWS_ACCESSKEY {}

# Secret Key
variable AWS_SECRETKEY {}

# Region
variable AWS_REGION {}

variable "instance_type" {}

variable "ami"{}

#virtual private network
variable "my_vpc" {
    default = {
        cidr="172.32.0.0/16"
        subnet_cidr= ["172.32.1.0/24","172.32.2.0/24"]
        vpc_name= "practice_vpc"
        subnet_name= ["practice_subnet1","practice_subnet2"]
    }

  
}