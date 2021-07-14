/*
    ポリシードキュメント
        Kinesis Data FirehoseにS3の操作権限を付与する
 */
data "aws_iam_policy_document" "kinesis_data_firehose" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}",
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}/*"
    ]
  }
}

/*
    Kinesis Data Firehose の IAMロール
 */
module "kinesis_data_firehose_role" {
  source = "./iam_role"
  name   = "kinesis-data-firehose"
  // firehose.amazonaws.com を指定し、このIAMロールを Kinesis Data Firehose で使うことを宣言する
  identifier = "firehose.amazonaws.com"
  policy     = data.aws_iam_policy_document.kinesis_data_firehose.json
}

/*
    CloudWatch Logs の IAMロールのポリシードキュメント
        Kinesis Data Firehose操作権限とPassRole権限を付与する
        PassRoleとは？
            PassRole は、 AWS サービスに IAM ロールをパスするための権限を表します。
            PassRole という独立したアクションがあるわけではありません。
            アクセス許可のみ
        IAMロールについてはこちらの記事を参考にするとよさそうです
            https://dev.classmethod.jp/articles/iam-role-passrole-assumerole/
 */
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:ap-northeast-1:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::*:role/cloudwatch-logs"]
  }
}

/*
    CloudWatch Logs の IAMロール
 */
module "cloudwatch_logs_role" {
  source = "./iam_role"
  name   = "cloudwatch-logs"
  // logs.ap-northeast-1.amazonaws.com を指定して CouldWatch Logs で使うことを宣言
  identifier = "logs.ap-northeast-1.amazonaws.com"
  policy     = data.aws_iam_policy_document.cloudwatch_logs.json
}

/*
    CloudWatch Logsサブスクリプションフィルタ
 */
resource "aws_cloudwatch_log_subscription_filter" "practice_terrafrom_kinesis_filter" {
  name           = "practice-terrafrom-kinesis-filter"
  log_group_name = aws_cloudwatch_log_group.for_ecs_scheduled_tasks.name
  // ログの送信先として Kinesis Data Firehose 配信ストリームを指定する
  destination_arn = aws_kinesis_firehose_delivery_stream.practice_terrafrom_kinesis.arn
  // Kinesisに流すデータをフィルタリングすることができる。今回はフィルタリングせずにすべて臆する設定を記述している
  filter_pattern = "[]"
  role_arn       = module.cloudwatch_logs_role.iam_role_arn
}
