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
        Name = "practice_terrafrom"
    }
}
