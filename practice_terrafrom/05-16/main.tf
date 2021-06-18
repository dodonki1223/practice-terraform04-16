// 実行するアカウント情報
provider "aws" {
    region  = "ap-northeast-1"
    profile = "terraform"
}

// GitHubプロバイダ
provider "github" {
    organization = "dodonki1223"
}
