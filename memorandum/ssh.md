````markdown
# ローカル環境と本番環境の SSH 接続を正しく設計する  
〜 GitHub デプロイを支える基盤づくり 〜

本記事では、  
**ローカル開発環境・本番環境（EC2）・GitHub** をつなぐ  
SSH 接続の設計と構築手順をまとめる。

Docker や HTTPS の前提として、  
**安全にコードを運ぶための SSH 設計**に重点を置く。

---

## 全体像（先に結論）

最終的に構築した接続関係は以下。

```text
[ローカル仮想環境]
  │
  │ SSH（EC2用キー）
  ▼
[EC2 本番環境]
  │
  │ SSH（Deploy Key）
  ▼
[GitHub]
````

重要なポイントは：

* ローカル ↔ 本番 ↔ GitHub は **それぞれ別の SSH 接続**
* 同じ鍵を使い回さない
* 接続の「方向」と「役割」を明確にすること

---

## 前提条件

* ローカルPC上に Linux 仮想環境（VM / WSL / Docker など）
* 本番環境として EC2（Ubuntu）
* EC2 作成時に SSH キーペア（`.pem`）を作成済み
* セキュリティグループで **22番ポート（SSH）を許可**

---

## 1. ローカル仮想環境に Git と SSH クライアントを用意する

### Git のインストール

```bash
sudo apt update
sudo apt install -y git
```

確認：

```bash
git --version
```

---

### SSH クライアントの確認

```bash
ssh -V
```

入っていない場合：

```bash
sudo apt install -y openssh-client
```

---

## 2. ローカル仮想環境 → GitHub への SSH 接続

### SSH 鍵の作成（ローカル用）

```bash
ssh-keygen -t ed25519 -C "local-dev"
```

* 保存先：`~/.ssh/id_ed25519`
* パスフレーズ：任意

---

### 公開鍵を確認

```bash
cat ~/.ssh/id_ed25519.pub
```

---

### GitHub に SSH 鍵を登録

GitHub
→ Settings
→ SSH and GPG keys
→ New SSH key

* Title: `local-dev`
* Key: `id_ed25519.pub` の内容

---

### 接続テスト

```bash
ssh -T git@github.com
```

成功例：

```text
Hi username! You've successfully authenticated.
```

---

## 3. ローカル環境から本番環境（EC2）へ SSH 接続する

### EC2 用 SSH 鍵を配置

EC2 作成時に取得した `xxx.pem` を使用する。

```bash
mv ~/Downloads/xxx.pem ~/.ssh/
chmod 600 ~/.ssh/xxx.pem
```

※ 権限設定をしないと SSH は拒否される。

---

### EC2 へ SSH 接続

```bash
ssh -i ~/.ssh/xxx.pem ubuntu@<EC2のパブリックIP>
```

成功すると：

```text
ubuntu@ip-xxx-xxx-xxx-xxx:~$
```

が表示される。

---

### known_hosts への登録

初回接続時：

```text
Are you sure you want to continue connecting (yes/no)?
```

`yes` を入力すると：

* 接続先 fingerprint が `~/.ssh/known_hosts` に保存される
* 次回以降は警告なしで接続可能

---

## 4. 本番環境（EC2）に Git をインストール

```bash
sudo apt update
sudo apt install -y git
```

確認：

```bash
git --version
```

---

## 5. 本番環境 → GitHub の SSH 接続（Deploy Key）

### 本番用 SSH 鍵を作成

```bash
ssh-keygen -t ed25519 -C "ec2-production"
```

* 保存先：`~/.ssh/id_ed25519`
* パスフレーズ：省略可

---

### 公開鍵を確認

```bash
cat ~/.ssh/id_ed25519.pub
```

---

### GitHub に Deploy Key を登録

GitHub
→ 対象リポジトリ
→ Settings
→ Deploy keys
→ Add deploy key

* Title: `ec2-production`
* Key: 上記公開鍵
* 必要に応じて **Allow write access**

#### Deploy Key を使う理由

* 本番サーバは 1 リポジトリ専用
* 個人アカウントの鍵を置かずに済む
* セキュリティと責務が明確

---

### 本番環境から GitHub 接続確認

```bash
ssh -T git@github.com
```

---

## 6. 本番環境でリポジトリを clone

```bash
git clone git@github.com:username/repository.git
```

以降の更新は：

```bash
git pull
```

---

## 7. 実際の運用フロー

```text
① ローカル仮想環境でコード修正
② localhost で動作確認
③ git commit / git push
④ ローカル → EC2 へ SSH
⑤ EC2 で git pull
⑥ Docker / Nginx 再起動
```

### 運用ルール

* 本番環境で直接コード編集しない
* 本番は「pull するだけ」にする
* 変更履歴はすべて GitHub に残す

---

## 8. よくある誤解

### ❌ ローカルと本番が相互に SSH 接続する？

→ **しない**

* ローカル → 本番：EC2 の鍵
* 本番 → GitHub：Deploy Key
* ローカル → GitHub：個人用 SSH 鍵

**接続は常に一方向で役割が違う。**

---

## 9. 学び・設計のポイント

* SSH 鍵は **環境ごとに分ける**
* 接続の「方向」を意識する
* 本番環境は最小権限で GitHub と接続
* Git + SSH が安定するとデプロイが圧倒的に楽になる

---

## おわりに

Docker や HTTPS よりも前に、
**SSH 接続の設計を正しく行うことが運用の安定性を左右する**。

今回の構成は、
個人開発でありながら実務でも通用する形になったと感じている。

同じ構成を作る人の参考になれば幸いである。


