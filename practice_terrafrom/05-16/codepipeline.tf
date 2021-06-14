/*
    CodePipeline - ポリシードキュメント
        以下の権限を与える
            ・ステージ間でデータを受け渡すためのS3操作権限
            ・「14.3.2 CodeBuildプロジェクト」を起動するためのCodeBuild操作権限
            ・ECSにDockerイメージをデプロイするためのECS操作権限
            ・CodeBuildやECSにロールを渡すためのPassRole権限
 */
data "aws_iam_policy_document" "codepipeline" {
    statement {
        effect    = "Allow"
        resources = ["*"]

        actions = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild",
            "ecs:DescribeServices",
            "ecs:DescribeTaskDefinition",
            "ecs:DescribeTasks",
            "ecs:ListTasks",
            "ecs:RegisterTaskDefinition",
            "ecs:UpdateService",
            "iam:PassRole",
        ]
    }
}

/*
    CodeBuild - IAMロール
 */
module "codepipeline_role" {
    source     = "./iam_role"
    name       = "codepipeline"
    identifier = "codepipeline.amazonaws.com"
    policy     = data.aws_iam_policy_document.codepipeline.json
}
