output "redis_host" {
  description = "ElastiCache Redis endpoint address"
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = aws_elasticache_cluster.this.port
}
