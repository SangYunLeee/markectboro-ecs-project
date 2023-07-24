output "loadbalancer_dns" {
  value = aws_lb.backend_lb.dns_name
}

output "repository_url" {
  value = aws_ecr_repository.private_repo.repository_url
}