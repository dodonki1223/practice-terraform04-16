/*
    ElastiCacheパラメータグループ
 */
resource "aws_elasticache_parameter_group" "practice_terrafrom_ec" {
    name   = "practice-terrafrom-ec"
    // MemcachedとRedisをサポートしている
    family = "redis5.0"

    // コストの低い「クラスタモード無効」に設定します
    parameter {
        name  = "cluster-enabled"
        value = "no"
    }
}
