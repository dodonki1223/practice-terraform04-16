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
