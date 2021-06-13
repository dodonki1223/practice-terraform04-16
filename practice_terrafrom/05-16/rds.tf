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
