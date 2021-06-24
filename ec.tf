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

/*
    ElastiCacheレプリケーショングループ
 */
resource "aws_elasticache_replication_group" "practice_terrafrom_ec_rg" {
    // Redisん３エンドポイントで使う識別子を設定する
    replication_group_id          = "practice-terrafrom-ec-rg"
    replication_group_description = "Cluster Disabled"
    // 「memcached」か「redis」を設定する
    engine                        = "redis"
    engine_version                = "5.0.4"
    // ノード数を指定する、ノード数はプライマリノードとレプリカノードの合計値です
    // 「3」を指定した場合は、プライマリノードがひとつ、レプリカノードがふたつという意味になります
    number_cache_clusters         = 3
    // ノードの種類によってCPU・メモリ・ネットワーク帯域のサイズが異なります、要件に合わせて変更します
    node_type                     = "cache.m3.medium"
    // スナップショット作成が毎日行われます。snapshot_windowで作成タイミングを指定します（設定はUTCで行うこと）
    // スナップショット保存期間をsnapshot_retention_limitで設定できます。キャッシュとして利用する場合h長期保存は不要です
    snapshot_window               = "09:10-10:10"
    snapshot_retention_limit      = 7
    // ElastiCacheではメンテナンスが定期的に行われます。maintennance_windowでメンテナンスのタイミングを設定します
    // バックアップと同様にUTCで設定します
    maintenance_window            = "mon:10:40-mon:11:40"
    // true にすることで自動フェイルオーバーが有効になります（マルチAZ化していることが前提です）
    automatic_failover_enabled    = true
    port                          = 6379
    // ElastiCacheの設定変更タイミングを制御します
    // RDSと同様に、設定辺国のタイミングには「即時」と「メンテナンスウィンドウ」があります、予期せぬ
    // ダウンタイムを避けるため、falseにして、メンテナンスウィンドウで設定変更を行うようにします
    apply_immediately             = false
    security_group_ids            = [module.redis_sg.security_group_id]
    parameter_group_name          = aws_elasticache_parameter_group.practice_terrafrom_ec_pg.name
    subnet_group_name             = aws_elasticache_subnet_group.practice_terrafrom_ec_sg.name
}

// セキュリティグループ
module "redis_sg" {
    source      = "./security_group"
    name        = "redis-sg"
    vpc_id      = aws_vpc.practice_terrafrom_vpc.id
    port        = 6379
    // VPC内からの通信のみを許可します
    cidr_blocks = [aws_vpc.practice_terrafrom_vpc.cidr_block]
}
