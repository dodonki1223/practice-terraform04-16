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
    policy     = data.aws_iam_policy_document.codebuild.json
}

/*
    CodeBuildプロジェクト
 */
resource "aws_codebuild_project" "practice_terrafrom_cb_p" {
    name         = "practice-terrafrom-cb-p"
    // CodeBuild用のIAMロールを設定する
    service_role = module.codebuild_role.iam_role_arn

    // ビルド対象のファイルをsourceで指定する
    source {
        // CODEPIPELINEと指定することでCodePipelineと連携することを宣言する
        type = "CODEPIPELINE"
    }

    // ビルド出力アーティファクトの格納先をartifactsで指定する
    artifacts {
        // CODEPIPELINEと指定することでCodePipelineと連携することを宣言する
        type = "CODEPIPELINE"
    }

    // ビルド環境
    environment {
        type            = "LINUX_CONTAINER"
        compute_type    = "BUILD_GENERAL1_SMALL"
        // "aws/codebuild/standard:2.0"はAWSが管理しているUbuntuベースのイメージ
        // このイメージを使う場合は「14.3.3ビルド仕様」でランタイムバージョンの指定が必要になります
        image           = "aws/codebuild/standard:2.0"
        //  ビルド時にDockerコマンドを使用するため、privileged_modeをtrueにして、特権を付与する
        privileged_mode = true
    }
}
