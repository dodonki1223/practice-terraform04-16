/*
    DBパラメータグループ
        MySQLのmy.cnfファイルに定義するようなデータベースの設定は、DBパラメーターグループで記述する
 */
resource "aws_db_parameter_group" "practice_terrafrom_rds_pg" {
    name   = "practice-terrafrom-rds-pg"
    // 「mysql5.7」のような、エンジン名とバージョンをあわせた値を設定します
    family = "mysql5.7"

    /*
        パラメータ
            設定のパラメータ名と値のペアを設定する
     */
    parameter {
        name  = "character_set_database"
        value = "utf8mb4"
    }

    parameter {
        name  = "character_set_server"
        value = "utf8mb4"
    }
}

/*
    DBオプショングループ
        データベースエンジンにオプション機能を追加する
 */
resource "aws_db_option_group" "practice_terrafrom_rds_og" {
    name                 = "practice-terrafrom-rds-og"
    //「mysql」のようなエンジン名を設定する
    engine_name          = "mysql"
    //「5.7」のようなメジャーバージョンを設定する
    major_engine_version = "5.7"

    option {
        // MariaDB監査プラグインを追加
        // ユーザーのログオンや実行したクエリなどのアクティビティを記録するためのプラグイン
        option_name = "MARIADB_AUDIT_PLUGIN"
    }
}

/*
    DBサブネットグループ
        DBを稼働させるサブネットをDBサブネットグループで定義する
        サブネットには異なるアベイラビリティゾーンのものを含む
 */
resource "aws_db_subnet_group" "practice_terrafrom_rds_sg" {
    name       = "practice-terrafrom-rds-sg"
    subnet_ids = [aws_subnet.practice_terrafrom_private_subnet_1a.id, aws_subnet.practice_terrafrom_private_subnet_1c.id]
}

/*
    DBインスタンス
 */
resource "aws_db_instance" "practice_terrafrom_rds" {
    // データベースのエンドポイントで使う識別子を設定する
    identifier                 = "practice-terrafrom"
    // 「mysql」のようなエンジン名をしてします、engine_versionにはパッチバージョンまで含めた「5.7.25」のようなバージョンを設定する
    engine                     = "mysql"
    engine_version             = "5.7.25"
    // インスタンスクラスでCPU・メモリ・ネットワーク帯域のサイズが決定する。要件に合わせた適宜変更する
    instance_class             = "db.t3.small"
    // ストレージ容量を設定する
    // storage_typeでは「汎用SSD」か「プロビジョンドIOPS」を設定する、gp2は汎用SSDを意味する
    // max_allocated_storageを設定すると、指定した容量まで自動的にスケールします
    allocated_storage          = 20
    max_allocated_storage      = 100
    storage_type               = "gp2"
    storage_encrypted          = true
    // KMSの鍵を指定すると、ディスク暗号化が有効にになる
    // デフォルトAWS KMS暗号鍵を使用すると、アカウントをまたいだスナップショットの共有ができなくなるため
    // レアケースですがディスク暗号化には自分で作成した鍵を使用したほうがよいです
    kms_key_id                 = aws_kms_key.practice_terrafrom_kms.arn
    // username と password でマスターユーザーの名前とパスワードをそれぞれ設定します
    username                   = "admin"
    password                   = "VeryStrongPassword!"
    // multi_az を true にするとマルチAZが有効になる
    multi_az                   = true
    // VPC外からのアクセスを遮断するためにpublicly_accessibleをfalseにする
    publicly_accessible        = false
    // FDSではバックアップが毎日行われます。backup_windowでバックアップのタイミングを設定する（設定はUTCで行うこと）
    // バックアップ期間は最大で35日、backup_retension_periodに設定する
    backup_window              = "09:10-09:40"
    backup_retention_period    = 30
    // RDSではメンテナンスが定期的に行われます。maintenance_windowでメンテナンスのタイミングを設定する（設定はバックアップと同じでUTCで行う）
    // メンテナンスにはOSやデータベースエンジンの更新が含まれ、メンテナンス自体を無効化することはできない
    // ただし、auto_minor_version_upgradeをfalseにすると自動マイナーバージョンアップは無効化できる
    maintenance_window         = "mon:10:10-mon:10:40"
    auto_minor_version_upgrade = false
    // 削除保護を有効にする
    deletion_protection        = true
    // インスタンス削除時のスナップショット作成のため、skip_final_snapshotをfalseにする
    skip_final_snapshot        = false
    port                       = 3306
    // RDSの設定変更のタイミングには「即時」と「メンテナンスウィンドウ」があります
    // RDSでは一部の設定変更に再起動が伴い、予期せぬダウンタイムが起こりえます、
    // そこで、apply_immediatelyをfalseにして即時反映を避けます
    apply_immediately          = false
    vpc_security_group_ids     = [module.mysql_sg.security_group_id]
    parameter_group_name       = aws_db_parameter_group.practice_terrafrom_rds_pg.name
    option_group_name          = aws_db_option_group.practice_terrafrom_rds_og.name
    db_subnet_group_name       = aws_db_subnet_group.practice_terrafrom_rds_sg.name

    lifecycle {
        ignore_changes = [password]
    }
}

// セキュリティグループ
module "mysql_sg" {
    source      = "./security_group"
    name        = "mysql-sg"
    vpc_id      = aws_vpc.practice_terrafrom_vpc.id
    port        = 3306
    // VPC内からの通信のみを許可します
    cidr_blocks = [aws_vpc.practice_terrafrom_vpc.cidr_block]
}
