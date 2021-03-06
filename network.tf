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
  cidr_block = "10.0.0.0/16"
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
resource "aws_subnet" "practice_terrafrom_public_subnet_1a" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id
  // 任意の単位で分割できる、こだわりがなければVPCで「/16」、サブネットでは「/24」にするとわかり良い
  cidr_block = "10.0.1.0/24"
  // サブネットで起動したインスタンスにパブリックIPアドレスを自動的に割り当ててくれる
  map_public_ip_on_launch = true
  // アベイラビリティゾーンをまたがったサブネットは作成できません
  // 複数のアベイラビリティゾーンで構成されたネットワークを「マルチAZ」と呼ぶ（可用性が向上する）
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "practice_terrafrom_public_subnet_1a"
  }
}

resource "aws_subnet" "practice_terrafrom_public_subnet_1c" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id
  // 任意の単位で分割できる、こだわりがなければVPCで「/16」、サブネットでは「/24」にするとわかり良い
  cidr_block = "10.0.2.0/24"
  // サブネットで起動したインスタンスにパブリックIPアドレスを自動的に割り当ててくれる
  map_public_ip_on_launch = true
  // アベイラビリティゾーンをまたがったサブネットは作成できません
  // 複数のアベイラビリティゾーンで構成されたネットワークを「マルチAZ」と呼ぶ（可用性が向上する）
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "practice_terrafrom_public_subnet_1c"
  }
}

/*
    プライベートサブネット
        VPCをさらに分割、インターネットからアクセスできないプライベートサブネットを作成
 */
resource "aws_subnet" "practice_terrafrom_private_subnet_1a" {
  vpc_id            = aws_vpc.practice_terrafrom_vpc.id
  cidr_block        = "10.0.65.0/24"
  availability_zone = "ap-northeast-1a"
  // パブリックIPアドレスは不要なのでfalseを設定
  map_public_ip_on_launch = false

  tags = {
    Name = "practice_terrafrom_private_subnet_1a"
  }
}

resource "aws_subnet" "practice_terrafrom_private_subnet_1c" {
  vpc_id            = aws_vpc.practice_terrafrom_vpc.id
  cidr_block        = "10.0.66.0/24"
  availability_zone = "ap-northeast-1c"
  // パブリックIPアドレスは不要なのでfalseを設定
  map_public_ip_on_launch = false

  tags = {
    Name = "practice_terrafrom_private_subnet_1c"
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

resource "aws_route_table" "practice_terrafrom_private_rt_1a" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id

  tags = {
    Name = "practice_terrafrom_private_rt_1a"
  }
}

resource "aws_route_table" "practice_terrafrom_private_rt_1c" {
  vpc_id = aws_vpc.practice_terrafrom_vpc.id

  tags = {
    Name = "practice_terrafrom_private_rt_1c"
  }
}

/*
    ルート
        ルートはルートテーブルの１レコードに該当する
 */
resource "aws_route" "practice_terrafrom_public_r" {
  route_table_id = aws_route_table.practice_terrafrom_public_rt.id
  gateway_id     = aws_internet_gateway.practice_terrafrom_igw.id
  // VPC以外への通信をインターネットゲートウェイ経由でインターネットへ流すためにデフォルトルート（0.0.0.0/0）を指定する
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "practice_terrafrom_private_r_1a" {
  route_table_id = aws_route_table.practice_terrafrom_private_rt_1a.id
  nat_gateway_id = aws_nat_gateway.practice_terrafrom_nat_gateway_1a.id
  // デフォルトルート（0.0.0.0/0）を設定し、NATゲートウェイにルーティングするよう設定する
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "practice_terrafrom_private_r_1c" {
  route_table_id = aws_route_table.practice_terrafrom_private_rt_1c.id
  nat_gateway_id = aws_nat_gateway.practice_terrafrom_nat_gateway_1c.id
  // デフォルトルート（0.0.0.0/0）を設定し、NATゲートウェイにルーティングするよう設定する
  destination_cidr_block = "0.0.0.0/0"
}

/*
    ルートテーブルの関連付け
        どのルートテーブルを使ってルーティングするかはサブネット単位で判断する
        関連付けを忘れた場合はデフォルトルートテーブルが自動的に使われる（アンチパターンなので使用すべきではない）
 */
resource "aws_route_table_association" "practice_terrafrom_public_1a_rta" {
  subnet_id      = aws_subnet.practice_terrafrom_public_subnet_1a.id
  route_table_id = aws_route_table.practice_terrafrom_public_rt.id
}

resource "aws_route_table_association" "practice_terrafrom_public_1c_rta" {
  subnet_id      = aws_subnet.practice_terrafrom_public_subnet_1c.id
  route_table_id = aws_route_table.practice_terrafrom_public_rt.id
}

resource "aws_route_table_association" "practice_terrafrom_private_1a_rta" {
  subnet_id      = aws_subnet.practice_terrafrom_private_subnet_1a.id
  route_table_id = aws_route_table.practice_terrafrom_private_rt_1a.id
}

resource "aws_route_table_association" "practice_terrafrom_private_1c_rta" {
  subnet_id      = aws_subnet.practice_terrafrom_private_subnet_1c.id
  route_table_id = aws_route_table.practice_terrafrom_private_rt_1c.id
}

/*
    EIP（Elastic IP Address）
        AWSではインスタンスを起動するたびに異なるIPアドレスが動的に割り当てられてしまうため、
        パブリックIPアドレスを固定できます
        今回はNATゲートウェイで使用するために作成しています
 */
resource "aws_eip" "practice_terrafrom_eip_1a" {
  vpc = true
  // 暗黙的にインターネットゲートウェイに依存しているため、インターネットゲートウェイ作成後に作成するように保証する
  // 初めて使用するリソースはTerraformのドキュメントを確認しdepends_onが必要かどうか確認すること
  depends_on = [aws_internet_gateway.practice_terrafrom_igw]

  tags = {
    Name = "practice_terrafrom_eip_1a"
  }
}

resource "aws_eip" "practice_terrafrom_eip_1c" {
  vpc = true
  // 暗黙的にインターネットゲートウェイに依存しているため、インターネットゲートウェイ作成後に作成するように保証する
  // 初めて使用するリソースはTerraformのドキュメントを確認しdepends_onが必要かどうか確認すること
  depends_on = [aws_internet_gateway.practice_terrafrom_igw]

  tags = {
    Name = "practice_terrafrom_eip_1c"
  }
}

/*
    NATゲートウェイ
        NAT（Network Address Translation）サーバーを導入すると、
        プライベートネットワークからインターネットへアクセスできるようになります
        EIP（Elastic IP Address）が必要です
        設定先はプライベートサブネットではなくパブリックサブネットです
 */
resource "aws_nat_gateway" "practice_terrafrom_nat_gateway_1a" {
  allocation_id = aws_eip.practice_terrafrom_eip_1a.id
  subnet_id     = aws_subnet.practice_terrafrom_public_subnet_1a.id
  // 暗黙的にインターネットゲートウェイに依存しているため、インターネットゲートウェイ作成後に作成するように保証する
  // 初めて使用するリソースはTerraformのドキュメントを確認しdepends_onが必要かどうか確認すること
  depends_on = [aws_internet_gateway.practice_terrafrom_igw]

  tags = {
    Name = "practice_terrafrom_nat_gateway_1a"
  }
}

resource "aws_nat_gateway" "practice_terrafrom_nat_gateway_1c" {
  allocation_id = aws_eip.practice_terrafrom_eip_1c.id
  subnet_id     = aws_subnet.practice_terrafrom_public_subnet_1c.id
  // 暗黙的にインターネットゲートウェイに依存しているため、インターネットゲートウェイ作成後に作成するように保証する
  // 初めて使用するリソースはTerraformのドキュメントを確認しdepends_onが必要かどうか確認すること
  depends_on = [aws_internet_gateway.practice_terrafrom_igw]

  tags = {
    Name = "practice_terrafrom_nat_gateway_1c"
  }
}

/*
    セキュリティグループ
        セキュリティグループはインスタンスレベルで動作する。サブネットレベルで動作するのは「ネットワークACL」
        OSへ到達する前にネットワークレベルでパケットをフィルタリングできる
 */
resource "aws_security_group" "practice_terrafrom_sg" {
  name   = "practice_terrafrom_sg"
  vpc_id = aws_vpc.practice_terrafrom_vpc.id

  tags = {
    Name = "practice_terrafrom_sg"
  }
}

/*
    セキュリティグループルール（インバウンド）
        デフォルトで許可されているのは同じセキュリティグループ内通信のみ（外からの通信は禁止）
            ステートフル（往路のみに適用される、復路は動的に開放される） - ホワイトリスト型
            ステートフルなので戻りのトラフィックを考慮しなくてよい
            すべてのルールを適用
 */
resource "aws_security_group_rule" "practice_terrafrom_sg_ingress" {
  // typeが「ingress」の場合はインバウンドルールになります
  type = "ingress"
  // HTTP通信ができるよう80番ポートを許可する
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.practice_terrafrom_sg.id
}

/*
    セキュリティグループルール（アウトバウンド）
        下記の設定ではすべての津神を許可する設定にしています
 */
resource "aws_security_group_rule" "practice_terrafrom_sg_egress" {
  // typeが「egress」の場合はアウトバウンドルールになります
  type      = "egress"
  from_port = 0
  to_port   = 0
  // –1 を指定するとすべてのタイプのトラフィックが許可される
  // 詳しくは：https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/security-group-rules-reference.html#sg-rules-other-instances
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.practice_terrafrom_sg.id
}
