terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

// 実行するアカウント情報
provider "aws" {
  region  = "ap-northeast-1"
  profile = "terraform"
}

// GitHubプロバイダ
provider "github" {
  owner = "dodonki1223"
}
