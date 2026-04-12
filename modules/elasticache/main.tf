resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.cluster_name}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.cluster_name}-redis-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${var.cluster_name}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [var.security_group_id]

  tags = {
    Name        = "${var.cluster_name}-redis"
    Project     = var.project_name
    Environment = var.environment
  }
}
