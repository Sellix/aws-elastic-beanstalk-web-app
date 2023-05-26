resource "aws_ecr_repository" "sellix-ecr" {
  for_each             = local.docker_environments
  name                 = "${var.tags["Project"]}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge({
    Name = "${var.tags["Project"]}-${each.key}"
    },
    var.tags
  )
}