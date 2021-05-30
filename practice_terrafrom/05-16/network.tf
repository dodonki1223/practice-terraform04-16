/*
    VPC
        VPC（Virtual Private Clound）は他のネットワークから論理的に切り離されている仮想ネットワークです
 */
resource "aws_vpc" "practice_terrafrom" {
    /*
        CIDR形式について
            VPCのIPv4アドレスの範囲を CIDR形式（xx.xx.xx.xx/xx）で指定する
            後から変更できないため、最初にきちんと設計すること
            詳しくは以下のサイトを確認すること
                https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/VPC_Subnets.html#vpc-resize
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
resource "aws_subnet" "practice_terrafrom_public" {
    vpc_id                  = aws_vpc.practice_terrafrom.id
    // 任意の単位で分割できる、こだわりがなければVPCで「/16」、サブネットでは「/24」にするとわかり良い
    cidr_block              = "10.0.0.0/24"
    // サブネットで起動したインスタンスにパブリックIPアドレスを自動的に割り当ててくれる
    map_public_ip_on_launch = true
    // アベイラビリティゾーンをまたがったサブネットは作成できません
    // 複数のアベイラビリティゾーンで構成されたネットワークを「マルチAZ」と呼ぶ（可用性が向上する）
    availability_zone       = "ap-northeast-1a"

    tags = {
        Name = "practice_terrafrom_public"
    }
}

/*
    インターネットゲートウェイ
        VPCとインターネット間で通信ができるようにするため、インターネットゲートウェイを作成します
        VPCは隔離されたネットワークなので単体ではインターネットと接続できません
 */
resource "aws_internet_gateway" "practice_terrafrom_gateway" {
    vpc_id = aws_vpc.practice_terrafrom.id

    tags = {
        Name = "practice_terrafrom_igw"
    }
}
