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
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObjectAcl",
            "s3:PutObject",
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild",
            "codestar-connections:UseConnection",
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
    role_arn = module.codepipeline_role.iam_role_arn

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
            owner            = "AWS"
            provider         = "CodeStarSourceConnection"
            version          = "1"
            output_artifacts = ["source_output"]

            configuration = {
                ConnectionArn     = aws_codestarconnections_connection.practice_terrafrom_github.arn
                FullRepositoryId  = "dodonki1223/practice-terraform04-16"
                BranchName        = "main"
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
            version          = "1"
            input_artifacts  = ["source_output"]
            output_artifacts = ["build_output"]

            configuration = {
                ProjectName   = aws_codebuild_project.practice_terrafrom_cb_p.id
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
            version          = "1"
            input_artifacts  = ["build_output"]

            /*
                imagedefinitions.json
                    name で指定したコンテナを、imageUriに指定したイメージで更新します
                    ECS Fargateの場合、latest タグでも必ずdocker pullするため、デプロイ
                    ごとにタグを変更する必要がありません
                    name に指定するのは：aws_ecs_task_definition
                    imageUriに指定するのは：aws_ecs_task_definitionのfamily
             */
            configuration = {
                ClusterName   = aws_ecs_cluster.practice_terrafrom_ecs.name 
                ServiceName   = aws_ecs_service.practice_terrafrom_ecs_service.name
                FileName      = "imagedefinitions.json"
            }
        }
    }

    artifact_store {
        location = aws_s3_bucket.artifact.id
        type     = "S3"
    }
}

/*
    GitHubに接続用
        他の書きぶりとしてCodePipelineに直接GitHubとしているなどがある
 */
resource "aws_codestarconnections_connection" "practice_terrafrom_github" {
  name          = "practice-terrafrom-github"
  provider_type = "GitHub"
}

// GitHubのシークレットトークンを設定する
// 秘匿情報なのでベタ書きは良くない……
locals {
    webhook_secret = "NankaSugoiKeyNiSuruze"
}

/*
    CodePipeline Webhook
        GitHubからWebhookを受け取るためにCodePipeline Webhookを作成
        予め作成しておいた GitHubのトークンを環境変数に設定しておく必要がある
        設定しないと認証が通らない
            export GITHUB_TOKEN=xxxxxxx
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
    authentication_configuration {
        secret_token = local.webhook_secret
    }

    // CodePiplelineの起動条件を指定することができる
    // aws_codepipelineで指定したmainブランチのときのみ起動するように設定する
    filter {
        json_path    = "$.ref"
        match_equals = "refs/heads/{Branch}"
    }
}

/*
    GitHub Webhook
        GitHub上でのイベントを検知し、コードの変更を通知するGitHub Webhookを定義します
        CodePipelineではWebhookのリソースを通知する側・される側のそれぞれで実装する
 */
resource "github_repository_webhook" "practice_terrafrom_grw" {
    repository = "practice-terraform04-16"

    // 通知設定
    //  CodepiepleのURLや、HMAC用の秘密鍵を指定します
    //  secretとsecret_tokenには同じ値を入れる必要があります
    configuration {
        url          = aws_codepipeline_webhook.practice_terrafrom_cp_webhook.url
        secret       = local.webhook_secret
        content_type = "json"
        insecure_ssl = false
    }

    // イベントではトリガーとなるイベントを設定する（push や pull_requestなども指定できる）
    events = ["push"]
}
