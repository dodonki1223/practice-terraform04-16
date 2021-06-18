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

/*
    CodePipeline
 */
resource "aws_codepipeline" "practice_terrafrom_cp" {
    name     = "practice-terrafrom-cp"
    role_arn = module.codebuild_role.iam_role_arn

    /*
        Sourceステージ：GitHubからソースコードを取得する
            GitHubリポジトリとブランチを指定する
            CodePipelineの起動はWebhookで行うためPollForSourceChangesはfalseにしてポーリングを無効にする
     */
    stage {
        name = "Source"

        action {
            name             = "Source"
            category         = "Source"
            owner            = "ThirdParty"
            provider         = "GitHub"
            version          = 1
            output_artifacts = ["Source"]

            configuration = {
                Owner                = "dodonki1223"
                Repo                 = "terraform-study"
                Branch               = "main"
                PollForSourceChanges = false
            }
        }
    }

    /*
        Buildステージ：CodeBuildを指定する
     */
    stage {
        name = "Build"

        action {
            name             = "Build"
            category         = "Build"
            owner            = "AWS"
            provider         = "CodeBuild"
            version          = 1
            input_artifacts  = ["Source"]
            output_artifacts = ["Build"]

            configuration = {
                ProjectName = aws_codebuild_project.practice_terrafrom_cb_p.id
            }
        }
    }

    /*
        Deployステージ：デプロイ先のECSクラスとECSサービスを指定する
     */
    stage {
        name = "Deploy"

        action {
            name             = "Deploy"
            category         = "Deploy"
            owner            = "AWS"
            provider         = "ECS"
            version          = 1
            input_artifacts  = ["Build"]

            /*
                imagedefinitions.json
                    name で指定したコンテナを、imageUriに指定したイメージで更新します
                    ECS Fargateの場合、latest タグでも必ずdocker pullするため、デプロイ
                    ごとにタグを変更する必要がありません
                    name に指定するのは：aws_ecs_task_definition
                    imageUriにしてするのは：aws_ecs_task_definitionのfamily
             */
            configuration = {
                ClusterName = aws_ecs_cluster.practice_terrafrom_ecs.name 
                ServiceName = aws_ecs_service.practice_terrafrom_ecs_service.name
                FileName    = "imagedefinitions.json"
            }
        }
    }

    artifact_store {
        location = aws_s3_bucket.artifact.id
        type     = "S3"
    }
}

/*
    CodePipeline Webhook
        GitHubからWebhookを受け取るためにCodePipeline Webhookを作成
 */
resource "aws_codepipeline_webhook" "practice_terrafrom_cp_webhook" {
    name            = "practice-terrafrom-cp-webhook"
    // Webhookを受け取ったら起動するパイプラインをtarget_piplelineで設定する
    // 最初に実行するアクションをtarget_actionを指定する
    target_pipeline = aws_codepipeline.practice_terrafrom_cp.name
    target_action   = "Source"
    // GitHubのWebhookはHMACによるメッセージ認証をサポートしています
    authentication  = "GITHUB_HMAC"

    // 20バイト以上のランダムな文字列を秘密鍵として指定する
    // `秘密鍵はtfstateファイルに平文で書き込まれます`
    // tfstateファイルへの書き込みを回避したい場合、Terraformでの管理は断念するしかしない
    authenticationn_configuration {
        secret_token = "VeryRandomStringMoreThan20Byte!"
    }

    // CodePiplelineの起動条件を指定することができる
    // aws_codepipelineで指定したmainブランチのときのみ起動するように設定する
    filter {
        json_path = "$.ref"
        match_equals = "refs/heads/{Branch}"
    }
}
