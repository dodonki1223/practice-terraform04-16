/*
    ECRリポジトリ（Elastic Container Registry）
 */
resource "aws_ecr_repository" "practice_terrafrom_ecr" {
    name = "practice-terrafrom-ecr"
}
