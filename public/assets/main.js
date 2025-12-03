(function () {
  // function to load and inject partial HTML files
  async function injectPartials() {
    const slots = document.querySelectorAll("[data-partial]");
    await Promise.all(
      Array.from(slots).map(async (slot) => {
        const name = slot.getAttribute("data-partial");
        try { const res = await fetch(`/partials/${name}.html`,{cache: "no-cache"});
          if (!res.ok) throw new Error(`Failed to load ${name}`);
          slot.outerHTML = await res.text();
        } catch (err) {
          console.error(err);
        }
      })
    )
  }
  
  // function to highlight the active navigation link
  function highlightNav() {
    // Get the current path without trailing slash
    var path = window.location.pathname.replace(/\/+$/, "") || "/"; 
    // Find all nav links and highlight the active one
    var links = document.querySelectorAll(".nav-link");
    links.forEach(function (link) {
      var nav = link.getAttribute("data-nav");
      // Determine if this link should be active
      var isActive = 
        (nav === "home" && (path === "/" || path === "/index.html")) ||
        (nav === "resume" && path.includes("/resume")) ||
        (nav === "portfolio" && path.includes("/portfolio"));
      link.classList.toggle("active", isActive);
    });
  }

  // function to load and render portfolio items
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

  // function to render portfolio items into the DOM
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

  document.addEventListener("DOMContentLoaded", async function () {
    await injectPartials();
    highlightNav();
    loadPortfolio();
  });

})();
