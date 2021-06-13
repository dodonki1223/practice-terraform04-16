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
