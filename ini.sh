#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(pwd)"

echo "=== Creating directories ==="
mkdir -p "$PROJECT_ROOT/diagrams"
mkdir -p "$PROJECT_ROOT/requirement"
mkdir -p "$PROJECT_ROOT/public/assets"
mkdir -p "$PROJECT_ROOT/logs/nginx"

echo "=== Creating requirements.md ==="
cat << 'EOL' > "$PROJECT_ROOT/requirement/requirements.md"
# Resume Website 要件定義

## 1. プロジェクト概要

本プロジェクトは、開発者自身のレジュメおよびポートフォリオ・プロジェクトを公開する静的ウェブサイトを作成し、
AWS EC2 インスタンス上にデプロイすることを目的とする。
バックエンドは主に「ウェブサーバのセットアップ・セキュリティ・デプロイフロー」を学習・経験することに重点を置く。

## 2. 利用者・ステークホルダー

- エンドユーザー（訪問者）
- サイトオーナー（開発者本人）

## 3. 機能要件（抜粋）

- サブドメインからのアクセス（例: resume.example.org）
- ホームページ / レジュメページ / ポートフォリオページの提供
- レジュメ PDF のダウンロードリンク提供
- 共通レイアウト（ヘッダー・ナビゲーション・フッター）の適用
- 静的ファイル（HTML/CSS/JS/JSON/PDF）配信

## 4. 非機能要件（抜粋）

- HTTPS アクセス (TLS 終端は Nginx or ALB)
- 年間稼働率 99% 以上を目標
- Docker / Nginx / EC2 を用いた再現性の高い環境
- 単一コマンドでローカル → 本番へデプロイ可能なフロー

EOL

echo "=== Creating task.md ==="
cat << 'EOL' > "$PROJECT_ROOT/requirement/task.md"
# タスクリスト

## 1. 要件定義
- [ ] requirements/requirements.md を整備
- [ ] システム構成図・アーキテクチャの確認

## 2. UML 図
- [ ] usecase.pu / activity.pu / sequence.pu / component.pu / class.pu の作成・更新

## 3. フロントエンド
- [ ] public/index.html / resume.html / portfolio.html / 404.html の作成
- [ ] public/assets/style.css のスタイル実装
- [ ] public/assets/main.js で JSON 読み込み & DOM レンダリング実装
- [ ] public/assets/portfolio.json のデータ入力
- [ ] public/assets/resume.pdf の配置

## 4. バックエンド / インフラ
- [ ] Dockerfile の作成
- [ ] docker-compose.yml の作成
- [ ] nginx.conf の作成
- [ ] EC2 上で docker compose up によりデプロイ

## 5. HTTPS / デプロイ
- [ ] ドメイン・DNS 設定
- [ ] TLS 証明書取得と Nginx への設定
- [ ] ローカル → 本番へのデプロイスクリプト整備

EOL

echo "=== Creating Dockerfile ==="
cat << 'EOL' > "$PROJECT_ROOT/Dockerfile"
FROM nginx:stable-alpine

RUN apk add --no-cache bash

COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY ./public /usr/share/nginx/html

EXPOSE 80
EOL

echo "=== Creating docker-compose.yml ==="
cat << 'EOL' > "$PROJECT_ROOT/docker-compose.yml"
version: "3.9"

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: resume-website
    ports:
      - "80:80"
    restart: unless-stopped
    volumes:
      - ./public:/usr/share/nginx/html:ro
      - ./logs/nginx:/var/log/nginx
    environment:
      - TZ=Asia/Tokyo

networks:
  default:
    name: resume-network
EOL

echo "=== Creating nginx.conf ==="
cat << 'EOL' > "$PROJECT_ROOT/nginx.conf"
server {
    listen 80;
    server_name resume.example.org portfolio.example.org localhost;

    root /usr/share/nginx/html;
    index index.html;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";

    location / {
        try_files $uri $uri/ =404;
    }

    location /assets/ {
        try_files $uri =404;
    }

    error_page 404 /404.html;
}
EOL

echo "=== Creating PlantUML diagrams ==="
cat << 'EOL' > "$PROJECT_ROOT/diagrams/arch.pu"
@startuml arch
title "Resume Website アーキテクチャ概要"

actor "Visitor\n(ブラウザ)" as User

node "AWS EC2\n(nginx-server)" as EC2 {
  node "Docker Engine" as Docker {
    node "nginx コンテナ" as Nginx {
      folder "/usr/share/nginx/html" as WebRoot {
        [index.html]
        [resume.html]
        [portfolio.html]
        folder "assets" {
          [style.css]
          [main.js]
          [portfolio.json]
          [resume.pdf]
          [images...]
        }
      }
    }
  }
}

User -down-> EC2 : HTTPS (443)\nHTTP (80, 初期セットアップ)

EC2 -down-> Nginx : docker network\nport 80
Nginx --> WebRoot : 静的ファイル配信

@enduml
EOL

cat << 'EOL' > "$PROJECT_ROOT/diagrams/usecase.pu"
@startuml usecase
left to right direction
skinparam packageStyle rectangle
title "Resume Website ユースケース図"

actor "Visitor" as Visitor
actor "Site Owner\n(Developer)" as Owner

rectangle "Resume Website" {
  usecase "ホームページを閲覧する" as UC_Home
  usecase "レジュメを閲覧する" as UC_ViewResume
  usecase "レジュメ PDF をダウンロードする" as UC_DownloadResume
  usecase "ポートフォリオ一覧を閲覧する" as UC_ViewPortfolio
  usecase "ポートフォリオ詳細を読む" as UC_ViewPortfolioDetail

  usecase "ポートフォリオ JSON を編集する" as UC_EditPortfolioJson
  usecase "サイトをデプロイする" as UC_DeploySite
}

Visitor --> UC_Home
Visitor --> UC_ViewResume
Visitor --> UC_DownloadResume
Visitor --> UC_ViewPortfolio
Visitor --> UC_ViewPortfolioDetail

Owner --> UC_EditPortfolioJson
Owner --> UC_DeploySite

@enduml
EOL

cat << 'EOL' > "$PROJECT_ROOT/diagrams/activity.pu"
@startuml activity
title "ポートフォリオ閲覧フロー（JSON 読み込み）"

start

:ユーザーが\n/portfolio.html にアクセス;
:ブラウザが HTML/CSS/JS を読み込む;

:JavaScript 初期化\n(main.js);
:fetch('/assets/portfolio.json') を実行;

if (HTTP 200?) then (はい)
  :JSON をパース;
  :ポートフォリオ配列を\n公開日降順にソート;
  :各エントリをカード要素として\nDOM に追加;
  :画面に一覧を表示;
else (いいえ)
  :エラーメッセージを DOM に表示;
endif

stop
@enduml
EOL

cat << 'EOL' > "$PROJECT_ROOT/diagrams/sequence.pu"
@startuml sequence
title "ポートフォリオ一覧表示のシーケンス"

actor Visitor
participant "Browser\n(HTML/CSS/JS)" as Browser
participant "Nginx" as Nginx
database "portfolio.json\n(static file)" as JsonFile

Visitor -> Browser : /portfolio.html にアクセス
Browser -> Nginx : GET /portfolio.html
Nginx --> Browser : 200 OK + HTML

Browser -> Nginx : GET /assets/style.css
Nginx --> Browser : 200 OK + CSS

Browser -> Nginx : GET /assets/main.js
Nginx --> Browser : 200 OK + JS

Browser -> Browser : DOMContentLoaded\nmain.js 初期化

Browser -> Nginx : GET /assets/portfolio.json (AJAX)
Nginx -> JsonFile : スタティックファイル読み込み
JsonFile --> Nginx : portfolio.json
Nginx --> Browser : 200 OK + JSON

Browser -> Browser : JSON パース\n→ DOM 要素生成\n→ 画面表示

@enduml
EOL

cat << 'EOL' > "$PROJECT_ROOT/diagrams/component.pu"
@startuml component
title "Resume Website コンポーネント図"

package "Presentation (Browser)" {
  [index.html]
  [resume.html]
  [portfolio.html]
  component "main.js" as MainJS
  component "style.css" as StyleCSS
}

package "Static Content" {
  component "portfolio.json" as PortfolioJson
  component "resume.pdf" as ResumePDF
  component "images/*" as Images
}

node "Nginx コンテナ" {
  [Nginx]
}

node "AWS EC2" {
  [Docker Engine]
}

[index.html] -- MainJS
[resume.html] -- MainJS
[portfolio.html] -- MainJS
[index.html] -- StyleCSS
[resume.html] -- StyleCSS
[portfolio.html] -- StyleCSS

MainJS --> PortfolioJson
[resume.html] --> ResumePDF

Nginx --> index.html
Nginx --> resume.html
Nginx --> portfolio.html
Nginx --> PortfolioJson
Nginx --> ResumePDF
Nginx --> Images

[Docker Engine] --> Nginx

@enduml
EOL

cat << 'EOL' > "$PROJECT_ROOT/diagrams/class.pu"
@startuml class
title "フロントエンドクラス図（概念）"

class PortfolioItem {
  +id: number
  +title: string
  +summary: string
  +content: string
  +source: string
  +thumbnail: string
  +date: Date
}

class PortfolioRepository {
  +endpoint: string
  +fetchAll(): Promise<List<PortfolioItem>>
}

class PortfolioRenderer {
  +containerSelector: string
  +renderList(items: List<PortfolioItem>): void
  +renderError(message: string): void
}

class NavHighlighter {
  +highlight(currentPath: string): void
}

PortfolioRepository "1" --> "*" PortfolioItem
PortfolioRenderer ..> PortfolioItem
PortfolioRenderer ..> PortfolioRepository
NavHighlighter ..> "HTMLDocument"

@enduml
EOL

echo "=== Creating basic HTML files ==="
cat << 'EOL' > "$PROJECT_ROOT/public/index.html"
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>Your Name - Software Engineer</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <header>
    <div class="logo">Your Name</div>
    <nav>
      <a href="/" class="nav-link" data-nav="home">Home</a>
      <a href="/resume.html" class="nav-link" data-nav="resume">Resume</a>
      <a href="/portfolio.html" class="nav-link" data-nav="portfolio">Portfolio</a>
    </nav>
  </header>
  <main>
    <section class="hero">
      <h1>Software Engineer</h1>
      <p>短い自己紹介文をここに記述します。</p>
      <div class="hero-actions">
        <a class="btn" href="/resume.html">View Resume</a>
        <a class="btn secondary" href="/portfolio.html">View Portfolio</a>
      </div>
    </section>
  </main>
  <footer>
    <small>© 2025 Your Name</small>
  </footer>
  <script src="/assets/main.js"></script>
</body>
</html>
EOL

cat << 'EOL' > "$PROJECT_ROOT/public/resume.html"
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>Resume - Your Name</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <header>
    <div class="logo">Your Name</div>
    <nav>
      <a href="/" class="nav-link" data-nav="home">Home</a>
      <a href="/resume.html" class="nav-link" data-nav="resume">Resume</a>
      <a href="/portfolio.html" class="nav-link" data-nav="portfolio">Portfolio</a>
    </nav>
  </header>
  <main>
    <section>
      <h1>Resume</h1>
      <p><a class="btn" href="/assets/resume.pdf" target="_blank" rel="noopener">Download PDF</a></p>
    </section>
    <section id="profile">
      <h2>Profile</h2>
      <p>自己紹介文をここに記述します。</p>
    </section>
    <section id="skills">
      <h2>Skills</h2>
      <ul>
        <li>Languages: Python, JavaScript, ...</li>
        <li>Frameworks: React, Node.js, ...</li>
      </ul>
    </section>
    <section id="experience">
      <h2>Experience</h2>
      <p>職務経歴を記述します。</p>
    </section>
  </main>
  <footer>
    <small>© 2025 Your Name</small>
  </footer>
  <script src="/assets/main.js"></script>
</body>
</html>
EOL

cat << 'EOL' > "$PROJECT_ROOT/public/portfolio.html"
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>Portfolio - Your Name</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <header>
    <div class="logo">Your Name</div>
    <nav>
      <a href="/" class="nav-link" data-nav="home">Home</a>
      <a href="/resume.html" class="nav-link" data-nav="resume">Resume</a>
      <a href="/portfolio.html" class="nav-link" data-nav="portfolio">Portfolio</a>
    </nav>
  </header>
  <main>
    <section>
      <h1>Portfolio</h1>
      <p>これまでに作成したプロジェクトの一覧です。</p>
      <div id="portfolio-list" class="portfolio-list">
        <!-- JavaScript により JSON から動的に生成 -->
      </div>
      <div id="portfolio-error" class="error-message" aria-live="polite"></div>
    </section>
  </main>
  <footer>
    <small>© 2025 Your Name</small>
  </footer>
  <script src="/assets/main.js"></script>
</body>
</html>
EOL

cat << 'EOL' > "$PROJECT_ROOT/public/404.html"
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>404 Not Found</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="/assets/style.css">
</head>
<body>
  <main class="center">
    <h1>404 - ページが見つかりません</h1>
    <p><a href="/">ホームに戻る</a></p>
  </main>
</body>
</html>
EOL

echo "=== Creating style.css ==="
cat << 'EOL' > "$PROJECT_ROOT/public/assets/style.css"
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  line-height: 1.6;
  color: #222;
}
header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1.5rem;
  border-bottom: 1px solid #eee;
}
.logo {
  font-weight: 700;
}
nav a {
  margin-left: 1rem;
  text-decoration: none;
  color: #333;
}
nav a.active {
  border-bottom: 2px solid #007acc;
}
main {
  max-width: 960px;
  padding: 1.5rem;
  margin: 0 auto;
}
footer {
  border-top: 1px solid #eee;
  padding: 1rem 1.5rem;
  text-align: center;
  font-size: 0.8rem;
  color: #666;
}
.hero {
  padding: 2rem 0;
}
.hero-actions .btn {
  margin-right: 0.5rem;
}
.btn {
  display: inline-block;
  padding: 0.5rem 1rem;
  background: #007acc;
  color: #fff;
  text-decoration: none;
  border-radius: 4px;
}
.btn.secondary {
  background: #555;
}
.portfolio-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1rem;
}
.portfolio-card {
  border: 1px solid #eee;
  border-radius: 4px;
  overflow: hidden;
  background: #fff;
}
.portfolio-card img {
  width: 100%;
  height: 160px;
  object-fit: cover;
}
.portfolio-card-content {
  padding: 0.75rem 1rem;
}
.portfolio-card h2 {
  margin-top: 0;
  font-size: 1.1rem;
}
.error-message {
  margin-top: 1rem;
  color: #d00;
}
@media (max-width: 600px) {
  header {
    flex-direction: column;
    align-items: flex-start;
  }
  nav {
    margin-top: 0.5rem;
  }
}
EOL

echo "=== Creating main.js ==="
cat << 'EOL' > "$PROJECT_ROOT/public/assets/main.js"
(function () {
  function highlightNav() {
    var path = window.location.pathname;
    var links = document.querySelectorAll(".nav-link");
    links.forEach(function (link) {
      var nav = link.getAttribute("data-nav");
      if (nav === "home" && (path === "/" || path === "/index.html")) {
        link.classList.add("active");
      } else if (nav === "resume" && path.indexOf("resume") !== -1) {
        link.classList.add("active");
      } else if (nav === "portfolio" && path.indexOf("portfolio") !== -1) {
        link.classList.add("active");
      }
    });
  }

  async function loadPortfolio() {
    var listEl = document.getElementById("portfolio-list");
    if (!listEl) return; // ポートフォリオページ以外では何もしない

    var errorEl = document.getElementById("portfolio-error");
    try {
      var res = await fetch("/assets/portfolio.json", { cache: "no-cache" });
      if (!res.ok) throw new Error("Failed to load portfolio.json");
      var items = await res.json();
      items.sort(function (a, b) {
        return new Date(b.date) - new Date(a.date);
      });
      renderPortfolioList(items);
    } catch (e) {
      console.error(e);
      if (errorEl) {
        errorEl.textContent = "ポートフォリオを読み込めませんでした。時間をおいて再度お試しください。";
      }
    }
  }

  function renderPortfolioList(items) {
    var listEl = document.getElementById("portfolio-list");
    listEl.innerHTML = "";
    items.forEach(function (item) {
      var article = document.createElement("article");
      article.className = "portfolio-card";

      if (item.thumbnail) {
        var img = document.createElement("img");
        img.src = item.thumbnail;
        img.alt = item.title;
        article.appendChild(img);
      }

      var content = document.createElement("div");
      content.className = "portfolio-card-content";

      var h2 = document.createElement("h2");
      h2.textContent = item.title;
      content.appendChild(h2);

      var meta = document.createElement("p");
      meta.className = "meta";
      if (item.date) {
        var d = new Date(item.date);
        meta.textContent = d.toLocaleDateString("ja-JP");
      }
      content.appendChild(meta);

      var summary = document.createElement("p");
      summary.textContent = item.summary || "";
      content.appendChild(summary);

      if (item.source) {
        var link = document.createElement("a");
        link.href = item.source;
        link.target = "_blank";
        link.rel = "noopener";
        link.textContent = "Source";
        link.className = "btn secondary";
        content.appendChild(link);
      }

      article.appendChild(content);
      listEl.appendChild(article);
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    highlightNav();
    loadPortfolio();
  });
})();
EOL

echo "=== Creating sample portfolio.json ==="
cat << 'EOL' > "$PROJECT_ROOT/public/assets/portfolio.json"
[
  {
    "id": 1,
    "title": "\"FoodieFinder\" レストラン探索アプリ",
    "summary": "個々のユーザーの食事の嗜好に基づいて、最適なレストランを提案するモバイルアプリケーションです。",
    "content": "FoodieFinderは、個々のユーザーの食事の嗜好に基づいて、最適なレストランを提案するモバイルアプリケーションです。",
    "source": "https://github.com/",
    "thumbnail": "https://cdn.pixabay.com/photo/2018/04/11/03/13/food-3309418_1280.jpg",
    "date": "2023-07-16T00:00:00"
  },
  {
    "id": 2,
    "title": "\"BudgetMaster\" 個人予算管理ツール",
    "summary": "ユーザーが自分の収入と支出を追跡し、賢明な金融決定を下せるように支援するウェブベースのツールです。",
    "content": "BudgetMasterは、ユーザーが自分の収入と支出を追跡し、賢明な金融決定を下せるように支援するウェブベースのツールです。",
    "source": "https://github.com/",
    "thumbnail": "https://cdn.pixabay.com/photo/2017/10/26/17/40/dollar-2891817_1280.jpg",
    "date": "2023-07-16T00:00:00"
  }
]
EOL

echo "=== NOTE ==="
echo "resume.pdf は public/assets/resume.pdf として別途配置してください。"
echo "プロジェクト初期化完了。次のコマンドでローカル起動できます:"
echo "  docker compose up --build"

