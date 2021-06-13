/*
    ElastiCacheパラメータグループ
 */
resource "aws_elasticache_parameter_group" "practice_terrafrom_ec_pg" {
    name   = "practice-terrafrom-ec-pg"
    // MemcachedとRedisをサポートしている
    family = "redis5.0"

    // コストの低い「クラスタモード無効」に設定します
    parameter {
        name  = "cluster-enabled"
        value = "no"
    }
}

/*
    ElastiCacheサブネットグループ
 */
resource "aws_elasticache_subnet_group" "practice_terrafrom_ec_sg" {
    name       = "practice-terrafrom-ec-sg"
    subnet_ids = [aws_subnet.practice_terrafrom_private_subnet_1a.id, aws_subnet.practice_terrafrom_private_subnet_1c.id]
}
