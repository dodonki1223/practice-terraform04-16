/*
    覚えておくべき情報
        プライベートバケット
            ブロックパブリックアクセス
        パブリックバケット
        ログバケット
        暗号化
        バケットポリシー
        バケットの強制削除
 */

/*
    プライベートバケット
        外部に公開しないバケット
 */
resource "aws_s3_bucket" "private" {
    bucket = "private-dodonki-practice-terraform"

    versioning {
        enabled = true
    }

    /*
        暗号化を有効
            オブジェクト保存時に自動で暗号化し、オブジェクト参照時に自動で複合するようになる
            使い勝手が悪くなることがなくデメリットがない
     */
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

/*
    プライベートバケット - ブロックパブリックアクセス
        予期しないオブジェクトの公開を抑止できる
        既存の公開設定の削除、新規の公開設定をブロックなど細かい設定が可能
        特に理由がなければ、下記のようにすべての設定を有効にするべし
 */
resource "aws_s3_bucket_public_access_block" "private" {
    bucket                  = aws_s3_bucket.private.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

/*
    パブリックバケット
        外部に公開するバケット
 */
resource "aws_s3_bucket" "public" {
    bucket = "public-dodonki-practice-terraform"
    // アクセス権の設定です。デフォルトは「private」なので「public-read」を指定する
    acl    = "public-read"

    // CORS（Cross-Origin Resource Sharing）の設定
    cors_rule {
        allowed_origins = ["https://example.com"]
        allowed_methods = ["GET"]
        allowed_headers = ["*"]
        max_age_seconds = 3000
    }
}

/*
    ログバケット
        AWSの各種サービスがログを保存するためのログバケット
 */
resource "aws_s3_bucket" "alb_log" {
    bucket = "alb-log-dodonki-practice-terraform"
    // 中身が空でなくても無理やり削除する
    force_destroy = true

    /*
        ライフサイクルルールを設定し180日経過したファイルを自動的に削除し、
        ファイルが増えないようにする
        Athenaで運用する時はどうするべきがよいのか……
     */ 
    lifecycle_rule {
        enabled = true

        expiration {
            days = "180"
        }
    }
}

/*
    バケットポリシー
        ALBのログを格納するバケットのバケットポリシーの設定
 */
resource "aws_s3_bucket_policy" "alb_log" {
    bucket = aws_s3_bucket.alb_log.id
    policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
    statement {
        effect    = "Allow"
        actions   = ["s3:PutObject"]
        resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

        /*
            identifiers に設定した id は Region x ELB ごとに割り振られているIDを指定する
            詳しくは以下のURLを確認すること（今回はap-northeast-1のIDを設定）
                https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
         */
        principals {
            type        = "AWS"
            identifiers = ["582318560864"]
        }
    }
}

/*
    S3バケットの削除
        バケットの削除する場合はバケット内が空になっている必要がある
        バケット内が空になっていなくても強制的に削除する場合は以下のように設定する
        force_destroy = true を設定することで destroy コマンドでバケットを削除すること
        ができるようになる
        resource "aws_s3_bucket" "force_destroy" {
            bucket        = "force-destroy-dodonki-practice-terraform"
            force_destroy = true
        }
 */

/*
    アーティファクトストア
        CodePipelineの各ステージで、データの受け渡しに使用するアーティファクトストアを作成する
 */
resource "aws_s3_bucket" "artifact" {
    bucket = "practice-terrafrom-artifact"

    // ライフサイクルルールを設定し180日経過したファイルを自動的に削除し、ファイルが増えないようにする
    lifecycle_rule {
        enabled = true

        expiration {
            days = "180"
        }
    }
}

/*
    オペレーションログ
        SessionManagerの操作ログを自動保存するために、SSM Documentを作成する必要がある
        ログの保存先には、S3バケットとCloudWatch Logsを指定できます
 */
resource "aws_s3_bucket" "operation" {
    bucket = "practice-terrafrom-operation"

    lifecycle_rule {
        enabled = true

        expiration {
            days = "180"
        }
    }
}
