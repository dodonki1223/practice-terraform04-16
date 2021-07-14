/*
    覚えておくべき情報
        IAMロール
        IAMポリシー
        ポリシードキュメント
        信頼ポリシー
 */

// IAMロール、IAMポリシー、ポリシードキュメント、信頼ポリシーについて

variable "name" {}       // IAMロールとIAMポリシーの名前
variable "policy" {}     // ポリシードキュメント
variable "identifier" {} // IAMロールを関連付けるAWSのサービス識別子

/*
    IAMロール
        信頼ポリシーとロール名を指定する
        IAMロールはIAMポリシーを複数設定することができ、IAMポリシーをグルーピングすることができるもの
    IAMロールとIAMポリシーの関係
        以下のような関係です
            IAMロール１ - ポリシー１
                        - ポリシー２
                        - ポリシー３
            IAMロール２ - ポリシー２
                        - ポリシー３
                        - ポリシー４
 */
resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

/*
    ポリシードキュメントについて
        JSON 形式のポリシードキュメント
            Effect　：Allow（許可）またはDeny（拒否）
            Action　：なんのサービスで、どんな操作が実行できるか
            Resource：操作可能なリソースはなにか、「*」はすべてという意味になる
            {
                "version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": ["ec2:DescribeRegions"],
                        "Resource": ["*"]
                    }
                ]
            }
        aws_iam_policy_document を使用した記述
            data "aws_iam_policy_document" "allow_describe_regions" {
                statement {
                    effect    = "Allow"
                    actions   = ["ec2.DescribeRegions"] # リージョン一覧を取得する
                    resources = ["*"]
                }
            }
 */

/*
    ロール - 信頼ポリシー
        IAMロールで、自身をなんのサービスに関連付けるか宣言する必要がありその宣言を「信頼ポリシー」と呼ばれる
            以下のような設定の場合は「ec2.amazonaws.com」と指定されているのでEC2にのみ関連付けができるということ
                data "aws_iam_policy_document" "ec2_assume_role" {
                    statement {
                        actions = ["sts:AssumeRole"]

                        principals {
                            type        = "Service"
                            indetifiers = ["ec2.amazonaws.com"]
                        }
                    }
                }
 */
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}

/*
    IAMポリシー
        ポリシードキュメントを保持するリソース
 */
resource "aws_iam_policy" "default" {
  name   = var.name
  policy = var.policy
}

/*
    IAMポリシーのアタッチ
        IAMロールにIAMポリシーをアタッチします
 */
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}
