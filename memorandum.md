# Docker + Nginx + Let’s Encrypt で HTTPS 化した Resume Website 構築記録  
〜 ERR_CONNECTION_REFUSED と自動更新失敗を乗り越えるまで 〜

## はじめに

個人の Resume / Portfolio サイトを  
**EC2 + Docker + Nginx + Let’s Encrypt** で本番公開しました。

構成自体はシンプルですが、  
HTTPS 化と証明書の自動更新において **複数の罠にハマった** ため、  
実際に躓いたポイントと、その仮説検証・修正プロセスをまとめます。

同じ構成で詰まっている人の参考になれば幸いです。

---

## 構成概要

- EC2（Ubuntu 22.04）
- Docker / docker-compose
- Nginx
- Let’s Encrypt（certbot）
- GitHub SSH デプロイ
- 静的サイト（Resume / Portfolio）

---

## 問題①：HTTPS にすると ERR_CONNECTION_REFUSED が出る

### 発生した事象

- `docker ps` ではコンテナが起動している
- しかし `https://example.com` にアクセスすると  
  **ERR_CONNECTION_REFUSED**
- `curl https://localhost` も失敗

### 仮説

- 証明書の設定が間違っている？
- Security Group の 443 が閉じている？
- Docker のポート公開が効いていない？

### 検証

- Security Group → 443 は開いている
- `docker ps` → 80 / 443 が表示される
- しかし **STATUS が restarting**

```bash
docker ps
# STATUS: Restarting (1) ...
```

### 修正

コンテナが **起動 → エラー → 再起動** を繰り返していた。

原因は HTTPS 移行中の healthcheck。

* `wget https://localhost` が失敗
* `restart: unless-stopped` により無限再起動

一時的に healthcheck を無効化：

```yaml
# healthcheck:
#   test: ["CMD-SHELL", "wget -qO- https://localhost || exit 1"]
```

### 学び

* `docker ps` の **STATUS は必ず確認する**
* `restarting` はネットワーク以前に **アプリが落ちているサイン**
* HTTPS 移行中は healthcheck が地雷になりやすい

---

## 問題②：Nginx が 443 で起動しない

### 発生した事象

Nginx のログに以下が出力された：

```
nginx: [emerg] "gzip" directive is duplicate
```

### 仮説

* 自分で書いた nginx.conf と
* Nginx イメージのデフォルト設定が競合している？

### 検証

* `nginx:stable` イメージには最初から gzip 設定が存在
* `default.conf` にも `gzip on;` を書いていた

### 修正

* `gzip on;` を **default.conf から削除**
* ベースイメージの設定に任せる

### 学び

* Nginx は **duplicate directive で即起動失敗**
* 「念のため書く」は危険
* デフォルト設定との責務分離が重要

---

## 問題③：証明書はあるのに HTTPS が起動しない

### 発生した事象

```
cannot load certificate
No such file or directory
```

### 仮説

* `/etc/letsencrypt` が Docker にマウントされていない？
* ディレクトリ名が違う？

### 検証

```bash
ls /etc/letsencrypt/live/
# resume.example.com-0001
```

nginx.conf では `resume.example.com` を指定していた。

### 修正

* 実在するディレクトリ名に合わせる
* `/etc/letsencrypt` を volume mount

```yaml
- /etc/letsencrypt:/etc/letsencrypt:ro
```

### 学び

* certbot は `-0001` を自動付与することがある
* **1文字違いでも Nginx は起動しない**

---

## 問題④：certbot の自動更新（renew）が失敗する

### 発生した事象

```text
Could not bind TCP port 80 because it is already in use
```

### 仮説

* `standalone` モードは 80 番ポートを専有する
* Docker の Nginx が常時 80 を使用しているため衝突？

### 検証

* 初回取得は standalone で成功
* `certbot renew --dry-run` は常に失敗

### 修正：webroot 方式へ切り替え

#### ホスト側に webroot 用ディレクトリを作成

```bash
sudo mkdir -p /var/www/certbot
```

#### docker-compose.yml に volume を追加

```yaml
- /var/www/certbot:/var/www/certbot
```

#### nginx.conf に challenge 用 location を追加

```nginx
location /.well-known/acme-challenge/ {
    root /var/www/certbot;
}
```

#### certbot を webroot 方式で再実行

```bash
sudo certbot certonly \
  --webroot \
  -w /var/www/certbot \
  -d resume.example.com
```

#### 自動更新テスト

```bash
sudo certbot renew --dry-run
```

### 学び

* Docker + Nginx 常駐構成では **standalone は不向き**
* 本番運用では **webroot が正解**
* HTTPS は「取得」ではなく「更新」まで考える

---

## 最終的に得られた学び

* ERR_CONNECTION_REFUSED は SSL エラーとは限らない
* `restarting` は最優先で疑うべき状態
* Docker とホスト OS の責務分離を意識する
* 設定は「動く」だけでなく「運用できる」ことが重要

---

## おわりに

HTTPS 化は単なる証明書取得ではなく、
**運用を前提とした設計が必要**だと実感しました。

同じ構成で詰まっている人の助けになれば幸いです。


