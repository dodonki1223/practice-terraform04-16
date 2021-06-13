/*
    ECRへDockerイメージのプッシュ
        aws --profile terraform ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 300367504550.dkr.ecr.ap-northeast-1.amazonaws.com
        docker build -t 300367504550.dkr.ecr.ap-northeast-1.amazonaws.com/practice-terrafrom-ecr:latest ./hello-world/
        docker push 300367504550.dkr.ecr.ap-northeast-1.amazonaws.com/practice-terrafrom-ecr:latest
    詳しくは以下の公式ドキュメントを参考にするとよい
        https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/getting-started-cli.html
 */

/*
    ECRリポジトリ（Elastic Container Registry）
 */
resource "aws_ecr_repository" "practice_terrafrom_ecr" {
    name = "practice-terrafrom-ecr"
}

/*
    ECRライフサイクルポリシー
        ECRリポジトリに保存できるイメージ数には限りがあります
        詳しくは公式ドキュメントを参照すること：https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/LifecyclePolicies.html
 */
resource "aws_ecr_lifecycle_policy" "practice_terrafrom_ecr_lcp" {
    repository = aws_ecr_repository.practice_terrafrom_ecr.name

    // 「release」ではじまるイメージタグを30個までに制限している
    policy = <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep last 30 release tagged images",
                "selection": {
                    "tagStatus": "tagged",
                    "tagPrefixList": ["release"],
                    "countType": "imageCountMoreThan",
                    "countNumber": 30
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
EOF
}
