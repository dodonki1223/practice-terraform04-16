/*
    コンテナの設定管理
        ECSのようなコンテナ環境では、設定をコンテナ起動時に注入します
        実行環境ごとに異なる設定には次のようなものがあります
            データベースのホスト名・ユーザー名・パスワード
            TwitterやFacebookなどの外部サービスのクレデンシャル
            管理者あてのメールアドレス
            ※Railsのルーティング設定やSpringのDI設定のような、実行環境ごとに変化しない設定は
              アプリケーションコードと一緒に管理します
 */

/*
    SSMパラメータストア
        SSMパラメータストアに登録
            $ aws ssm put-parameter --name 'plain_name' --value 'plain value' --type String --profile terraform
            {
                "Version": 1,
                "Tier": "Standard"
            }
        登録したSSMパラメータストアを取得
            $ aws ssm get-parameter --output text --name 'plain_name' --query Parameter.Value --profile terraform
            plain value
        登録したSSMパラメータを更新
            $ aws ssm put-parameter --name 'plain_name' --value 'modified value' --type String --overwrite --profile terraform
            modified value
        SSMパラメータストアに登録（暗号化）
            $ aws ssm put-parameter --name 'encryption_name' --value 'encryption value' --type SecureString  --profile terraform
            {
                "Version": 1,
                "Tier": "Standard"
            }
        登録したSSMパラメータストアを取得（暗号化）
            $ aws ssm get-parameter --output text --query Parameter.Value --name 'encryption_name' --with-decryption --profile terraform
            encryption value
 */

/*
    平文での登録
 */
resource "aws_ssm_parameter" "db_username" {
    name        = "/db/username"
    value       = "root"
    type        = "String"
    description = "データベースのユーザー名"
}

/*
    暗号化での登録
        暗号化する値がソースコードに平文で書かれてしまう
        暗号化するような秘匿性の高い情報はバージョン管理対象外にすべきなので、
        このままでは使い物にならない
        「Terraformではダミー値を設定しておいて後でAWS CLIなどで更新する」という戦略を採用するとよい
            Terraformでapply後、以下のようなコマンドを叩くこと
            aws ssm put-parameter --name '/db/raw_password' --value 'ModifiedStrongPassword!' --type SecureString --overwrite --profile terraform
 */
resource "aws_ssm_parameter" "db_raw_password" {
    name        = "/db/password"
    value       = "VeryStrongPassword!"
    type        = "SecureString"
    description = "データベースのパスワード"

    lifecycle {
        ignore_changes = [value]
    }
}

/*
    オペレーションサーバー用のSSM Document
        SSM Document とは？
            Systems Manager がマネージドインスタンスで実行する操作を定義します
            実行時にパラメータを指定して使用できる事前設定済みのドキュメントが 100 件以上含まれています
        System Managerは何が嬉しいの？
            https://dev.classmethod.jp/articles/ssh-through-session-manager/
            IAMで認証・認可ができる
            ポート空け不要
            ログが取れる / ログを元に別AWSサービスをトリガできる
    オペレーションサーバーに接続する時は以下のようなコマンドを叩く
        aws ssm start-session --target EC2のインスタンスID --document-name SSM-SessionManagerRunShell --profile terraform
        ※事前にSession Manager Pluginをインストールしておくこと
 */
resource "aws_ssm_document" "session_manager_run_shell" {
    // SSM-SessionManagerRunShell を設定するとAWS CLIを使う時にオプション指定を省略できる
    name            = "SSM-SessionManagerRunShell"
    // type、format には session, json を指定する、SessionManager ではこの値は固定である
    document_type   = "Session"
    document_format = "JSON"

    content = <<EOF
    {
        "schemaVersion": "1.0",
        "description": "Document to hold regional settings for Session Manager",
        "sessionType": "Standard_Stream",
        "inputs": {
            "s3BucketName": "${aws_s3_bucket.operation.id}",
            "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.operation.name}"
        }
    }
EOF
}
