variable "aws_region" {
  default     = "ap-northeast-2"
}

variable "ACCESS_KEY_ID" {
  type        = string
}

variable "SECRET_KEY" {
  type        = string
  sensitive   = true
}

variable "ECR_IMAGE_URL" {
  type        = string
  default = "587649217574.dkr.ecr.ap-northeast-2.amazonaws.com/marketboro:0.1"
}