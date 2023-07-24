resource "aws_ecr_repository" "private_repo" {
  name = "tf-marketboro-backend"
  image_tag_mutability = "MUTABLE"
}