/*
    バッチ
        バッチ処理は、オンライン処理とは異なる関心事を有している
        アプリケーションレベルでどこまで制御し、ジョブ管理システムでどこまでサポートするかはしっかり設計する必要があります
        ＜バッチ設計の基本原則＞
            以下の４つの原則があります
                ジョブ管理
                エラーハンドリング
                リトライ
                依存関係制御

            ジョブ管理
                バッチは一定の周期で実行されますが、誰かがジョブの起動タイミングを制御しなければなりません。
                それがジョブ管理です。ジョブ管理は、バッチ処理では重要な関心事です。ジョブ管理の仕組みに問題が発生すると、
                最悪の場合、全ジョブが停止します。
                cron や ジョブ管理システム（RundeckやJPI）などを使用する
                    cron　　　　　　　：依存関係制御もできず、cronを動かすサーバーの運用にも手間がかかる
                    ジョブ管理システム：エラー通知やリトライ、依存関係制御の仕組みが組み込まれており、複雑なジョブの管理ができる、稼働させるサーバーの運用は課題として残る
            エラーハンドリング
                エラーハンドリングでは「エラー通知」が重要です
                なんらかの理由でバッチが失敗した場合、それを検知してリカバリーする必要があります
                またエラー発生時の「ロギング」も重要、スタックトレースなどの情報は、原因調査で必要になるため、確実にログ出力します
            リトライ
                バッチ処理が失敗した場合、リトライできなければなりません。自動で指定回数リトライできることが望ましい
                少なくとも、手動ではリトライできる必要がある
                リトライできるようアプリケーションを設計する必要があります
            依存関係制御
                ジョブが増えてくると依存関係制御が必要になります
                「ジョブAは必ずジョブBのあとに実行しなければならない」などはよくあります。単純に時間をずらして
                暗黙的な依存関係制御を行う場合もありますが、アンチパターンなので避けましょう。
 */

/*
    バッチ用CloudWatch Logs
        複数のバッチで使い回すこともできるがバッチごとに作成したほうが運用は楽です
 */
resource "aws_cloudwatch_log_group" "for_ecs_scheduled_tasks" {
  name              = "/ecs-scheduled-tasks/practice_terrafrom"
  retention_in_days = 180
}

/*
    バッチ用タスク定義
 */
resource "aws_ecs_task_definition" "practice_terrafrom_batch" {
  family                   = "practice-terrafrom-batch"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./batch_container_definition.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

/*
    CloudWatch イベントIAMロール
        CloudWatch イベントからECSを起動するためのIAMロール
 */
module "ecs_events_role" {
  source     = "./iam_role"
  name       = "ecs-events"
  identifier = "events.amazonaws.com"
  policy     = data.aws_iam_policy.ecs_events_role_policy.policy
}

// AmazonEC2ContainerServiceEventsRole ポリシーを使用すると「タスクを実行する」権限と「タスクにIAMロールを渡す」権限を付与できる
data "aws_iam_policy" "ecs_events_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

/*
    CloudWatchイベントルール
 */
resource "aws_cloudwatch_event_rule" "practice_terrafrom_batch" {
  name        = "practice-terrafrom-batch"
  description = "とても重要なバッチ処理です"
  // cron式とrate式をサポートしている
  // cron：「cron(0 8 * * ? *)」、タイムゾーンはUTCなので注意
  // rate：「rate(5 minutes)」、単位は「1の場合は単数形、それ以外は複数形」つまり「rate(1 hours)」や「rate(5 hour)」のように書くことはできない
  // 詳しくはこちらのドキュメントを：https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/events/ScheduledEvents.html
  schedule_expression = "cron(*/2 * * * ? *)"
}

/*
    CloudWatchイベントターゲット
        実行対象のジョブを定義する
        ECS Scheduled Tasksの場合は、タスク定義をターゲットに設定する
 */
resource "aws_cloudwatch_event_target" "practice_terrafrom_batch" {
  target_id = "practice-terrafrom-batch"
  // CloudWatchイベントルールを設定、これで定期的にCloudWatchイベントターゲットが実行される
  rule = aws_cloudwatch_event_rule.practice_terrafrom_batch.name
  // CloudWatchイベントIAMロールを設定する
  role_arn = module.ecs_events_role.iam_role_arn
  // ターゲットをarnで設定する、ECS Scheduled TasksではECSクラスタを指定する、さらに
  // ecs_targetで、タスクの実行時の設定を行います
  arn = aws_ecs_cluster.practice_terrafrom_ecs.arn

  // ecs_targetにはロードバランサーやヘルスチェックの設定はないがそれ以外はaws_ecs_serviceと同じ
  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    platform_version    = "1.3.0"
    task_definition_arn = aws_ecs_task_definition.practice_terrafrom_batch.arn

    network_configuration {
      assign_public_ip = "false"
      subnets          = [aws_subnet.practice_terrafrom_private_subnet_1a.id]
    }
  }
}
