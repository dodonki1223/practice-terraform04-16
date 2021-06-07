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
