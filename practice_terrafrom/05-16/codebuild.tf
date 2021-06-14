/*
    CodeBuild - ポリシードキュメント
        以下の権限を与える
            ・ビルド出力アーティファクトを保存するためのS3操作権限
            ・ビルドログを出力するためのCloudWatchLogs操作権限
            ・DockerイメージをプッシュするためのECR操作権限
 */
data "aws_iam_policy_document" "codebuild" {
    statement {
        effect    = "Allow"
        resources = ["*"]

        actions = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage",
        ]
    }
}

/*
    CodeBuild - IAMロール
 */
module "codebuild_role" {
    source     = "./iam_role"
    name       = "codebuild"
    identifier = "codebuild.amazonaws.com"
    policy = data.aws_iam_policy_document.codebuild.json
}
