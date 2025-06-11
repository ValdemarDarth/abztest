output "ec2_public_ip" {
  description = "Публічна IP-адреса EC2 інстансу"
  value       = aws_instance.wordpress.public_ip
}

output "rds_endpoint" {
  description = "Endpoint бази даних RDS"
  value       = aws_db_instance.wordpress.address
}

output "redis_endpoint" {
  description = "Endpoint Redis кластера"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}
