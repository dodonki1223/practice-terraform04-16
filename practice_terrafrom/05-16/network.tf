/*
    VPC
        VPC（Virtual Private Clound）は他のネットワークから論理的に切り離されている仮想ネットワークです
 */
resource "aws_vpc" "practice_terrafrom_vpc" {
    /*
        CIDR形式について
            VPCのIPv4アドレスの範囲を CIDR形式（xx.xx.xx.xx/xx）で指定する
            後から変更できないため、最初にきちんと設計すること
            詳しくは以下のサイトを確認すること
                https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/VPC_Subnets.html#vpc-resize
            こちらのBlack Beltの資料はわかりやすい
                https://d1.awsstatic.com/webinars/jp/pdf/services/20180418_AWS-BlackBelt_VPC.pdf
            VPC CIDR とサブネット数
                CIDRに「/16」を設定した場合のサブネット数とIPアドレス数
                サブネットマスク：/18, サブネット数：    4, サブネットあたりのIPアドレス数：16379
                サブネットマスク：/20, サブネット数：   16, サブネットあたりのIPアドレス数： 4091
                サブネットマスク：/22, サブネット数：   64, サブネットあたりのIPアドレス数： 1019
                サブネットマスク：/24, サブネット数：  256, サブネットあたりのIPアドレス数：  251
                サブネットマスク：/26, サブネット数： 1024, サブネットあたりのIPアドレス数：   59
                サブネットマスク：/28, サブネット数：16384, サブネットあたりのIPアドレス数：   11
     */
    cidr_block           = "10.0.0.0/16"
    /*
        名前解決
            enable_dns_support   = true：AWSのDNSサーバーによる名前解決を有効にする
            enable_dns_hostnames = true：VPC内のリソースにパブリックDNSホスト名を自動的に割り当てる
     */
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = "practice_terrafrom_vpc"
    }
}

/*
    パブリックサブネット
        VPCをさらに分割、インターネットからアクセス可能なパブリックサブネットを作成
 */
resource "aws_subnet" "practice_terrafrom_public_subnet" {
    vpc_id                  = aws_vpc.practice_terrafrom_vpc.id
    // 任意の単位で分割できる、こだわりがなければVPCで「/16」、サブネットでは「/24」にするとわかり良い
    cidr_block              = "10.0.0.0/24"
    // サブネットで起動したインスタンスにパブリックIPアドレスを自動的に割り当ててくれる
    map_public_ip_on_launch = true
    // アベイラビリティゾーンをまたがったサブネットは作成できません
    // 複数のアベイラビリティゾーンで構成されたネットワークを「マルチAZ」と呼ぶ（可用性が向上する）
    availability_zone       = "ap-northeast-1a"

    tags = {
        Name = "practice_terrafrom_public_subnet"
    }
}

/*
    プライベートサブネット
        VPCをさらに分割、インターネットからアクセスできないプライベートサブネットを作成
 */
resource "aws_subnet" "practice_terrafrom_private_subnet" {
    vpc_id                  = aws_vpc.practice_terrafrom_vpc.id
    cidr_block              = "10.0.64.0/24"
    availability_zone       = "ap-northeast-1a"
    // パブリックIPアドレスは不要なのでfalseを設定
    map_public_ip_on_launch = false

    tags = {
        Name = "practice_terrafrom_private_subnet"
    }
}

/*
    インターネットゲートウェイ
        VPCとインターネット間で通信ができるようにするため、インターネットゲートウェイを作成します
        VPCは隔離されたネットワークなので単体ではインターネットと接続できません
 */
resource "aws_internet_gateway" "practice_terrafrom_igw" {
    vpc_id = aws_vpc.practice_terrafrom_vpc.id

    tags = {
        Name = "practice_terrafrom_igw"
    }
}

/*
    ルートテーブル
        インターネットゲートウェイだけでは、またインターネットと通信できません
        ネットワークにデータを流すため、ルーティング情報を管理するルートテーブルが必要
        VPC内の通信を有効にするため、ローカルルートが自動的に作成されます
            Destination：10.0.0.0/16
            Target：local
 */
resource "aws_route_table" "practice_terrafrom_public_rt" {
    vpc_id = aws_vpc.practice_terrafrom_vpc.id

    tags = {
        Name = "practice_terrafrom_public_rt"
    }
}

resource "aws_route_table" "practice_terrafrom_private_rt" {
    vpc_id = aws_vpc.practice_terrafrom_vpc.id

    tags = {
        Name = "practice_terrafrom_private_rt"
    }
}

/*
    ルート
        ルートはルートテーブルの１レコードに該当する
 */
resource "aws_route" "practice_terrafrom_public_r" {
    route_table_id         = aws_route_table.practice_terrafrom_public_rt.id
    gateway_id             = aws_internet_gateway.practice_terrafrom_igw.id
    // VPC以外への通信をインターネットゲートウェイ経由でインターネットへ流すためにデフォルトルート（0.0.0.0/0）を指定する
    destination_cidr_block = "0.0.0.0/0"
}

/*
    ルートテーブルの関連付け
        どのルートテーブルを使ってルーティングするかはサブネット単位で判断する
        関連付けを忘れた場合はデフォルトルートテーブルが自動的に使われる（アンチパターンなので使用すべきではない）
 */
resource "aws_route_table_association" "practice_terrafrom_public_rta" {
    subnet_id      = aws_subnet.practice_terrafrom_public_subnet.id
    route_table_id = aws_route_table.practice_terrafrom_public_rt.id
}

resource "aws_route_table_association" "practice_terrafrom_private_rta" {
    subnet_id      = aws_subnet.practice_terrafrom_private_subnet.id
    route_table_id = aws_route_table.practice_terrafrom_private_rt.id
}
