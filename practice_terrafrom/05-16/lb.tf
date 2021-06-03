/*
    Application Load Balancer
        クロスゾーン負荷分散に標準で対応しており、複数のアベイラビリティゾーンの
        バックエンドサーバーに、リクエストを振り分けられます
            クロスゾーン負荷分散：https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html#cross-zone-load-balancing
 */
resource "aws_lb" "practice_terrafrom_alb" {
    name                       = "practiceterrafromalb"
    // ALB と NLB の作成が可能です（application or network を指定します）
    // CLB を作成する場合は aws_elb を使用する：https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elb
    load_balancer_type         = "application"
    // 「インターネット向け」なのか「VPC内部向け」なのかを指定する
    // falseを指定することで インターネット向けになる
    internal                   = false
    // タイムアウト設定 
    // 詳しくは：https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/application/application-load-balancers.html#connection-idle-timeout
    idle_timeout               = 60
    // 削除保護の設定でtrueにすることで本番環境で誤って削除されないようになる
    // NOTE: 試す段階で削除はしたいので一旦、コメントアウト
    // enable_deletion_protection = true

    // 異なるアベイラビリティゾーンのサブネットを指定して、クロスゾーン負荷分散を実現する
    subnets = [
        aws_subnet.practice_terrafrom_public_subnet_1a.id,
        aws_subnet.practice_terrafrom_public_subnet_1c.id
    ]

    // アクセスログの保存が有効になる
    access_logs {
        bucket  = aws_s3_bucket.alb_log.id
        enabled = true
    }

    security_groups = [
        module.http_sg.security_group_id,
        module.https_sg.security_group_id,
        module.http_redirect_sg.security_group_id,
    ]
}

/*
    セキュリティグループ
        モジュールで複数定義する
 */
// HTTPの80番ポートを許可する
module "http_sg" {
    source      = "./security_group"
    name        = "http-sg"
    vpc_id      = aws_vpc.practice_terrafrom_vpc.id
    port        = 80
    cidr_blocks = ["0.0.0.0/0"]
}

// HTTPSの443番ポートを許可する
module "https_sg" {
    source      = "./security_group"
    name        = "https-sg"
    vpc_id      = aws_vpc.practice_terrafrom_vpc.id
    port        = 443
    cidr_blocks = ["0.0.0.0/0"]
}

// HTTPのリダイレクトで使用する8080番ポートを許可する
module "http_redirect_sg" {
    source      = "./security_group"
    name        = "http_redirect_sg"
    vpc_id      = aws_vpc.practice_terrafrom_vpc.id
    port        = 8080
    cidr_blocks = ["0.0.0.0/0"]
}

/*
    リスナー
        どのポートのリクエストを受け付けるか設定する
        リスナーはALBに複数アタッチできます
 */
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.practice_terrafrom_alb.arn
    port              = 80
    // HTTP or HTTPS のみサポートしている
    protocol          = "HTTP"

    /*
        デフォルトアクション
            リスナーは複数のルールを設定して、異なるアクションを実行できます
            いずれのルールにも合致しない場合は、default_actionが実行される
            typeの種類に関してはこちらを：https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener#type
                forward       ：リクエストを別のターゲットグループに転送
                fixed-response：固定のHTTPレスポンスを応答
                redirect      ：別のURLにリダイレクト
                authenticate-cognito, authenticate-oidcなども存在します
     */
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "これは『HTTP』です"
            status_code = "200"
        }
    }
}

/*
    ホストゾーン
        ホストゾーンを使用する前にドメインの登録を済ませて置く必要があります
            ドメインの登録方法
                1. ドメイン名の入力
                2. 連絡先情報の入力
                3. 登録メールアドレスの有効性検証
            ※ドメインの登録はTerraformでは実行できません
        ホストゾーンはDNSレコードを束ねるリソースです
            Route 53でドメインを登録した場合は、自動的に作成される
            同時にNSレコードとSOAレコードも作成されます
            NSレコード ：管理を委託しているDNSサーバの名前が書かれている行
            SOAレコード：DNSで定義されるそのドメインについての情報の種類の１つで、ゾーンの管理のための情報や設定などを記述するためのもの
 */
data "aws_route53_zone" "dodonki" {
    name = "dodonki.com"
}

// ホストゾーンの作成
resource "aws_route53_zone" "test_dodonki" {
    name = "test.dodonki.com"
}

/*
    DNSレコード
        Aレコード　　：IPv4でホスト名とIPアドレスの関連付けを定義するレコード
        CNAMEレコード：正規ホスト名に対する別名を定義するレコード（特定のホスト名を別のドメイン名に転送するときなどに利用する）
　                      「ドメイン名→CNAMEレコードのドメイン名→IPアドレス」という流れで名前解決する
        ALIASレコード：AWSでのみ使用可能なDNSレコード、AWSプロダクトで利用するDNS名専用のCNAMEレコード風の挙動を実現するレコード
                        「ドメイン名→IPアドレス」という流れで名前解決する（CNAMEレコードに比べてパフォーマンスが改善される）
 */
resource "aws_route53_record" "dodonki" {
    zone_id = data.aws_route53_zone.dodonki.zone_id
    name    = data.aws_route53_zone.dodonki.name
    // AレコードやCNAMEレコードのタイプが指定可能です
    // AWS独自拡張のALIASレコードを使用する場合は「A」を指定する
    type    = "A"

    alias {
        name                   = aws_lb.practice_terrafrom_alb.dns_name
        zone_id                = aws_lb.practice_terrafrom_alb.zone_id
        evaluate_target_health = true
    }
}

/*
    検証用DNSレコード
        aws_acm_certificate リソースを参照する
        resource "aws_acm_certificate" "dodonki" で subject_alternative_names でドメインを追加した場合は
        そのドメイン用のDNSレコードも必要になるので注意
 */
resource "aws_route53_record" "dodonki_certificate" {
    name    = aws_acm_certificate.dodonki.domain_validation_options[0].resource_record_name
    type    = aws_acm_certificate.dodonki.domain_validation_options[0].resource_record_type
    records = [aws_acm_certificate.dodonki.domain_validation_options[0].resource_record_value]
    zone_id = data.aws_route53_zone.dodonki.id
    ttl     = 60
}

/*
    ACM（AWS Certificate Manager）
        SSL証明書をACMで作成する
        ACMは煩雑なSSL証明書の管理を担ってくれるマネージドサービスで、ドメイン検証をサポートしている
        ドメイン検証についてはこちら：https://docs.aws.amazon.com/ja_jp/acm/latest/userguide/domain-ownership-validation.html
 */
resource "aws_acm_certificate" "dodonki" {
    // ドメイン名を指定、「*.dodonki.com」のように指定すると、ワイルドカード証明書を発行できる
    domain_name               = aws_route53_record.dodonki.name
    // ドメインを追加したい場合は設定する
    // ["test.dodonki.com"]を指定すると「dodonki.com」と「test.dodonki.com」のSSL証明書を作成できる
    subject_alternative_names = []
    // 検証方法の設定、DNS検証 or Eメール検証を選択する
    // SSL証明書を自動更新したい場合はDNS検証を選択する
    // Eメール検証とDNS検証の使い分けがワケワカメ……
    validation_method         = "DNS"

    // 「新しいSSL証明書を作ってから、古いSSL証明書と差し替える」という挙動に変更する
    // ライフサイクルはTerraform独自の機能で、すべてのリソースに設定可能
    lifecycle {
        // create_before_destroy を true にすると「リソースを作成してから、リソースを削除する」という挙動になる
        // ちなみに通常のリソースの再作成は「リソースの削除をしてから、リソースを作成する」という挙動になる
        // create_before_destroy = true は通常のリソース再作成と逆の挙動になる
        create_before_destroy = true
    }
}

/*
    検証の待機
        apply時にSSL証明書の検証が完了するまで待ってくれる
        なにかのリソースを作るわけではない
 */
resource "aws_acm_certificate_validation" "dodonki" {
    certificate_arn         = aws_acm_certificate.dodonki.arn
    validation_record_fqdns = [aws_route53_record.dodonki_certificate.fqdn]
}

output "alb_dns_name" {
    value = aws_lb.practice_terrafrom_alb.dns_name
}

output "domain_name" {
    value = aws_route53_record.dodonki.name
}
