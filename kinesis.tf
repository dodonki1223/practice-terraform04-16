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
    IAMロール
 */
module "kinesis_data_firehose_role" {
    source     = "./iam_role"
    name       = "kinesis-data-firehose"
    // firehose.amazonaws.com を指定し、このIAMロールを Kinesis Data Firehose で使うことを宣言する
    identifier = "firehose.amazonaws.com"
    policy     = data.aws_iam_policy_document.kinesis_data_firehose.json
}
