variable "aws_region" {
  default     = "ap-northeast-2"
}

variable "ECR_IMAGE_URL" {
  type        = string
  default = "587649217574.dkr.ecr.ap-northeast-2.amazonaws.com/marketboro:0.5"
}