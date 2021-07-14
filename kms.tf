/*
    KMS（Key Management Service）
        暗号鍵を管理するマネージドサービスです
        KMSは暗号化戦略として、エンベロープ暗号化が採用されています
        データの暗号化と複合では、カスタマーマスターキーを直接使いません。そのかわりに、カスタマー
        マスターキーが自動生成したデータキーを使用して、暗号化と複合を行います
        KMSはAWSの各種サービスと統合されており、暗号化戦略を意識せずに使えます。単純にカスタマー
        マスターキーを指定すれば、自動的にデータの暗号化と複合を行うことができる

        エンベロープ暗号化についてはこちら
            https://docs.aws.amazon.com/ja_jp/kms/latest/developerguide/concepts.html#enveloping
        カスタマーマスターキー（CMK）
            AWS KMSに保存されているマスターキーのこと
 */

/*
    カスタマーマスターキー
 */
resource "aws_kms_key" "practice_terrafrom_kms" {
  description = "Example Customer Master Key"
  // 自動ローテーション、頻度は年に１度
  // ローテーション後も、複合に必要な古い暗号化マテリアルは保存される。
  // そのため、ローテーション前に暗号化したデータの復号が引き続き可能
  enable_key_rotation = true
  // 有効化・無効化
  // カスタマーマスターキーを無効化できる
  is_enabled = true
  // 削除待機時間（デフォルトは30日）、待機期間中であれば、いつでも削除を取り消せます
  // 「カスタマーマスターキーの削除は推奨されていない」、削除したカスタマーマスターキーで
  // 暗号化したデータは、いかなる手段でも複合できなくなるため、通常は無効化を選択すべき
  deletion_window_in_days = 20
}

/*
    エイリアス
        カスタマーマスターキーにエイリアスを設定することが可能です
        カスタマーマスターキーにはUUIDが割り当てられますが、分かりづらいため、
        エイリアスを設定するとよいです
 */
resource "aws_kms_alias" "practice_terrafrom_kms" {
  // エイリアスで設定する名前には「alias/」というプレフィックスが必ず必要なので注意
  name          = "alias/practice_terrafrom_kms"
  target_key_id = aws_kms_key.practice_terrafrom_kms.key_id
}
