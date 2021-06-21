/*
    SSHレスオペレーション
        EC2とSession Managerを組み合わせたオペレーションサーバーを構築する
        ＜運用＞
            EC2にはDockerだけインストール
            設定情報はSSMパラメータストアから取得しEC2では管理しないようにする
        ＜セキュリティ＞
            Session Managerを導入し、SSHログインを不要にする
            「SSHの鍵管理」も「SSHのポート開放」も行わない
            インターネットからのアクセスも遮断する
        ＜トレーサビリティ＞
            同じくSession Managerで、すべての操作ログを保存する
            コマンドの実行結果も自動的に残し、トレーサビリティを確保します
        ＜Session Manager＞
            SSHログインなしに、シェルアクセスを実現するサービスです
            専用のエージェントをインストールして、そのエージェント経由でコマンドを実行する
            Session Managerでは実際にログインすることなく、ログインしているかのようにオペレーションできる
            Amazon Linux2であれば、標準でエージェントがインストールされている
        ＜インスタンスプロファイル＞
            EC2は特殊で、直接IAMロールを関連付けできません
            かわりに、IAMロールをラップしたインスタンスプロファイルを関連付けて権限を付与する
 */

/*
    ポリシードキュメント
 */
data "aws_iam_policy_document" "ec2_for_ssm" {
    source_json = data.aws_iam_policy.ec2_for_ssm.policy

    statement {
        effect    = "Allow"
        resources = ["*"]

        // AmazonSSMManagedInstanceCore ポリシーをベースにし、S3バケットとCloudWatch Logsへの書き込み権限を付与する
        // SSMパラメータストアとECRへの参照権限を追加することでEC2上で「ECRに格納したイメージのdocker pull」と「SSM
        // パラメータストアから設定情報を注入したコンテナの起動」を実現できる
        actions = [
            "s3:PutObject",
            "logs:PutLogEvents",
            "logs:CreateLogStream",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssmGetParametersByPath",
            "kms:Decrypt",
        ]
    }
}

data "aws_iam_policy" "ec2_for_ssm" {
    arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

/*
    IAMロール
 */
module "ec2_for_ssm_role" {
    source     = "./iam_role"
    name       = "ec2-for-ssm"
    // 信頼ポリシーに「ec2.amazonaws.com」を指定し、このIAMロールをEC2インスタンスで使うことを宣言する
    identifier = "ec2.amazonaws.com"
    policy     = data.aws_iam_policy_document.ec2_for_ssm.json
}
