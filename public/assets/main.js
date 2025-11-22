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
