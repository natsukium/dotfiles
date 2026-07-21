/*
 * Progressive enhancements for the exported documentation. Everything here is
 * optional: with JS disabled the page still reads fine (the top collapsible TOC
 * remains), just without the breadcrumb bar, the on-this-page rail, and the
 * copy buttons.
 *
 *  1. Breadcrumb bar — a single fixed row showing the current section's
 *     ancestor path ("Parent › Child › …"), kept in sync with scrolling. CSS
 *     shows it only on narrow viewports, where the rail is hidden.
 *  2. On-this-page rail — the outline in the right margin (wide viewports),
 *     with the current section highlighted as you scroll.
 *  3. Copy buttons — one per code block, copying the block's text.
 */
(function () {
  "use strict";

  function ready(fn) {
    if (document.readyState !== "loading") fn();
    else document.addEventListener("DOMContentLoaded", fn);
  }

  ready(function () {
    setupNav();
    setupCopyButtons();
  });

  // Breadcrumb bar + "On this page" rail, both driven by one scroll spy.
  function setupNav() {
    var headings = Array.prototype.slice.call(
      document.querySelectorAll(
        ".outline-2 > h2, .outline-3 > h3, .outline-4 > h4," + ".outline-5 > h5, .outline-6 > h6",
      ),
    );
    if (!headings.length) return;

    // The line under the fixed bar (--stick tall) where a section counts as
    // "current": once its heading scrolls above this, we're inside it.
    var rootFontSize = parseFloat(getComputedStyle(document.documentElement).fontSize);
    var line =
      parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--stick")) *
        rootFontSize +
      4;

    // Breadcrumb bar: the current ancestor path on one line.
    var bar = document.createElement("nav");
    bar.className = "crumb-bar";
    bar.setAttribute("aria-label", "Breadcrumb");
    bar.hidden = true;
    var crumbs = document.createElement("div");
    crumbs.className = "crumb-bar-inner";
    bar.appendChild(crumbs);
    document.body.appendChild(bar);

    // "On this page" rail: the exported TOC cloned into a sticky right column,
    // its links keyed by section id for scroll-spy highlighting. CSS decides
    // when it is actually visible (wide viewports only).
    var railLinks = {};
    var rail = null;
    var toc = document.getElementById("text-table-of-contents");
    if (toc) {
      var titleEl = document.querySelector("#table-of-contents > summary");
      var title = (titleEl && titleEl.textContent.trim()) || "Contents";
      rail = document.createElement("nav");
      rail.className = "toc-rail";
      rail.setAttribute("aria-label", title);
      var railTitle = document.createElement("div");
      railTitle.className = "toc-rail-title";
      railTitle.textContent = title;
      var railList = document.createElement("div");
      railList.innerHTML = toc.innerHTML;
      rail.appendChild(railTitle);
      rail.appendChild(railList);
      document.body.appendChild(rail);
      Array.prototype.forEach.call(rail.querySelectorAll('a[href^="#"]'), function (a) {
        railLinks[a.getAttribute("href").slice(1)] = a;
      });
    }

    // Cache each section's document-space extent so scrolling reads no layout.
    var cache = [];
    function recompute() {
      cache = headings.map(function (h) {
        var c = h.parentElement;
        return {
          id: h.id,
          el: h,
          top: c.offsetTop,
          bottom: c.offsetTop + c.offsetHeight,
        };
      });
    }
    recompute();

    var lastKey = null;
    var lit = [];
    var ticking = false;
    function update() {
      ticking = false;
      var y = window.scrollY + line;
      // Nested containers straddling the line are the current section and its
      // ancestors, already in document order.
      var path = cache.filter(function (o) {
        return o.top <= y && o.bottom > y;
      });
      var key = path
        .map(function (o) {
          return o.id;
        })
        .join(">");
      if (key === lastKey) return;
      lastKey = key;

      // Breadcrumb
      if (!path.length) {
        bar.hidden = true;
      } else {
        crumbs.textContent = "";
        path.forEach(function (o, i) {
          if (i) {
            var sep = document.createElement("span");
            sep.className = "crumb-sep";
            sep.setAttribute("aria-hidden", "true");
            sep.textContent = "›";
            crumbs.appendChild(sep);
          }
          var a = document.createElement("a");
          a.className = "crumb";
          a.href = "#" + o.id;
          a.textContent = crumbLabel(o.el);
          crumbs.appendChild(a);
        });
        bar.hidden = false;
      }

      // Rail scroll-spy: light the ancestor path, accent the deepest section.
      lit.forEach(function (a) {
        a.classList.remove("in-path", "active");
      });
      lit = [];
      path.forEach(function (o, i) {
        var a = railLinks[o.id];
        if (!a) return;
        a.classList.add(i === path.length - 1 ? "active" : "in-path");
        lit.push(a);
      });
      if (rail && lit.length) keepVisible(rail, lit[lit.length - 1]);
    }

    function onScroll() {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(update);
    }

    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener(
      "resize",
      function () {
        recompute();
        onScroll();
      },
      { passive: true },
    );
    // Late layout shifts (web fonts) move the cached offsets; refresh once the
    // page has fully loaded.
    window.addEventListener("load", function () {
      recompute();
      onScroll();
    });
    update();
  }

  // Keep the active rail link inside the rail's scrollport.
  function keepVisible(rail, a) {
    var top = a.offsetTop;
    var bottom = top + a.offsetHeight;
    if (top < rail.scrollTop || bottom > rail.scrollTop + rail.clientHeight) {
      rail.scrollTop = top - rail.clientHeight / 2;
    }
  }

  // The heading text without its leading section number.
  function crumbLabel(h) {
    var num = h.querySelector('[class^="section-number-"]');
    var text = h.textContent;
    if (num) text = text.replace(num.textContent, "");
    return text.trim();
  }

  function setupCopyButtons() {
    var containers = document.querySelectorAll(".org-src-container");
    Array.prototype.forEach.call(containers, function (container) {
      var pre = container.querySelector("pre");
      // The exporter gives every code block a header bar; the button lives in
      // it, beside the block's tangle target.
      var head = container.querySelector(".src-head");
      if (!pre || !head) return;

      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "copy-btn";
      btn.textContent = "Copy";
      btn.setAttribute("aria-label", "Copy code to clipboard");

      btn.addEventListener("click", function () {
        // innerText keeps the line breaks; reading from <pre> rather than the
        // container keeps the header bar out of the copied text.
        copyText(pre.innerText).then(function (ok) {
          btn.textContent = ok ? "Copied!" : "Failed";
          btn.classList.toggle("copied", ok);
          setTimeout(function () {
            btn.textContent = "Copy";
            btn.classList.remove("copied");
          }, 1500);
        });
      });

      head.appendChild(btn);
    });
  }

  function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text).then(
        function () {
          return true;
        },
        function () {
          return fallbackCopy(text);
        },
      );
    }
    return Promise.resolve(fallbackCopy(text));
  }

  // execCommand path for browsers without the async clipboard API (or when it
  // rejects, e.g. an insecure origin).
  function fallbackCopy(text) {
    try {
      var ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      var ok = document.execCommand("copy");
      document.body.removeChild(ta);
      return ok;
    } catch (e) {
      return false;
    }
  }
})();
