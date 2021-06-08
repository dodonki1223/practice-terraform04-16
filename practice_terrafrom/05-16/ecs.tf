/*
    ECS（Elastic Container Service）
        AWSにはEKS（Elastic Kubernetes Service）もあるがECSの方がシンプルである
        起動タイプ
            EC2起動　　：ホストサーバーへSSHログインしてデバッグが可能、ホストサーバーの管理が必要で運用が煩雑
            Fargate起動：ホストサーバーの管理が不要、SSHログインができないためデバッグの難易度が高い
 */

/*
    ECSクラスタ
 */
resource "aws_ecs_cluster" "practice_terrafrom_ecs" {
    name = "practice-terrafrom-ecs"
}

/*
    タスク定義
        コンテナの実行単位を「タスク」と呼ぶ
            例えば、Railsアプリケーションの前段にnginxを配置する場合、ひとつのタスクの中で
            Railsコンテナとnginxコンテナが実行される
        タスクは「タスク定義」から生成される
            タスク定義はコンテナ実行時の設定を記述する
        オブジェクト指向言語で例えるとタスク定義はクラスでタスクはインスタンスです
 */
resource "aws_ecs_task_definition" "practice_terrafrom_ecs_task" {
    /*
        ファミリーはタスク定義名のプレフィックス
        ファミリーにリビジョン番号を付けたものがタスク定義名になる（practice-terrafrom:1, practice-terrafrom:2……）
        タスク定義の更新時にインクリメントされる
     */
    family                   = "practice-terrafrom"
    /*
        タスクサイズ
            cpuはcpuユニットの整数表現（1024とか）かvcpuの文字列表現（1vcpu）で設定する
            memoryはMiBの整数表現（1024）か,GBの文字列表現（1GB）で設定
            設定できる組み合わせは決まっていて、例えばcpuに256を指定する場合、memoryで指定できる値は512・1024・2048のいずれか
     */
    cpu                      = "256"
    memory                   = "512"
    // Fagate起動タイプの場合はawsvpcを指定する
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    /*
        コンテナ定義
            name　　　　：名前
            image　　　 ：使用するコンテナイメージ
            essential　 ：タスク実行に必須かどうかのフラグ
            portMappings：マッピングするコンテナのポート番号
     */
    container_definitions    = file("./container_definitions.json")
}

/*
    ECSサービス
        起動するタスクの数を定義でき、指定した数のタスクを維持します（なんらかの理由でタスクが終了しても自動的に新しいタスクを起動していくれる）
        ECSサービスはALBとの橋渡し役にもなる、インターネットからのリクエストはALBで受け、そのリクエストをコンテナにフォワードする
 */
resource "aws_ecs_service" "practice_terrafrom_ecs_service" {
    name                              = "practice-terrafrom-ecs-service"
    cluster                           = aws_ecs_cluster.practice_terrafrom_ecs.arn
    task_definition                   = aws_ecs_task_definition.practice_terrafrom_ecs_task.arn
    // 維持するタスク数：指定した数が1だとコンテナが異常終了すると、ECSサービスがタスクを再起動するまでアクセスできなくなるため本番環境では2以上を指定すること
    desired_count                     = 2
    launch_type                       = "FARGATE"
    // プラットフォームバージョン：デフォルトはLATESTだが、LATESTは最新バージョンでない場合があるため、明示的にバージョンを指定すること
    // 詳しくはこちらを参照すること：https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/platform_versions.html
    platform_version                  = "1.3.0"
    // ヘルスチェック猶予機関：十分な猶予期間を設定しておかないとヘルスチェックに引っかかり、タスクの終了と起動を無限に繰り返してしま
    //                         うため0以上を指定すること（デフォルトは0なため）
    health_check_grace_period_seconds = 60

    /*
        ネットクワーク構成
            サブネットとセキュリティグループを設定する
            パブリックIPアドレスを割り当てるか設定する（今回はプライベートネットワークで起動するため設定はしない）
     */
    network_configuration {
        assign_public_ip = false
        security_groups  = [module.nginx_sg.security_group_id]

        subnets = [
            aws_subnet.practice_terrafrom_private_subnet_1a.id,
            aws_subnet.practice_terrafrom_private_subnet_1c.id,
        ]
    }

    /*
        ロードバランサー
            ターゲットグループとコンテナの名前・ポート番号を指定してろオードバランサーと紐付ける
                container_name  = コンテナ定義のname（container_definitions.jsonのこと）
                containerj_port = コンテナ定義のportMappings.contanerPort（container_definitions.jsonのこと）
     */
    load_balancer {
        target_group_arn = aws_lb_target_group.practice_terrafrom_tg.arn
        container_name   = "practice-terrafrom"
        container_port   = 80
    }

    /*
        ライフサイクル
            Fargateの場合、デプロイのたびにタスク定義が更新され、plan時に差分がでるため、
            Terraformではタスク定義の変更を無視すべきです
            ignore_changesに指定したパラメータは、リソースの初回作成時を除き、変更を無視するようになる
     */
    lifecycle {
        ignore_changes = [task_definition]
    }
}

module "nginx_sg" {
    source      = "./security_group"
    name        = "nginx-sg"
    vpc_id      = aws_vpc.practice_terrafrom_vpc.id
    port        = 80
    cidr_blocks = [aws_vpc.practice_terrafrom_vpc.cidr_block]
}

/*
    CloudWatch Logs
        AWS各種サービスと統合されており、あらゆるログを収集できるマネージドサービスです
        Fargateはホストサーバーにログインできず、コンテナのログを直接確認できません。そこでCloudWatch Logsと
        連携し、ログを記録できるようにする
 */
resource "aws_cloudwatch_log_group" "practice_terrafrom_for_ecs" {
    name              = "/ecs/practice_terrafrom"
    // ログの保存期間を指定する
    retention_in_days = 180
}

/*
    IAMポリシーデータソース
        AmazonECSTaskExecutionRolePolicyはAWSが管理しているポリシーです
 */
data "aws_iam_policy" "ecs_task_execution_role_policy" {
    arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

/*
    ポリシードキュメント
 */
data "aws_iam_policy_document" "ecs_task_execution" {
    // source_jsonを使用すると既存のポリシーを継承できます
    source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

    // AmazonECSTaskExecutionRolePolicyを継承し「12.2.3SSMパラメータストアとECSの統合で」必要な権限を追加しておきます
    statement {
        effect    = "Allow"
        actions   = ["ssm:GetParameters", "kms:Decrypt"]
        resources = ["*"]
    }
}

/*
    IAMロール
 */
module "ecs_task_execution_role" {
    source     = "./iam_role"
    name       = "ecs-task-execution"
    // 「ecs-tasks.amazonaws.com」を指定してIAMロールでECSで使うことを宣言します
    identifier = "ecs-tasks.amazonaws.com"
    policy     = data.aws_iam_policy_document.ecs_task_execution.json
}
