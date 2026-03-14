document.addEventListener("DOMContentLoaded", () => {
	addCodeLabels();
	addCopyButtons();
	trackActiveSection();
});

/* Parse "src src-LANG" class and insert a language label */
function addCodeLabels() {
	document.querySelectorAll("pre.src").forEach((pre) => {
		var match = pre.className.match(/\bsrc-(\S+)/);
		if (!match) return;
		var lang = match[1];
		var label = document.createElement("span");
		label.className = "code-lang-label";
		label.textContent = lang;
		pre.parentElement.insertBefore(label, pre);
	});
}

/* Add a copy button to each code block */
function addCopyButtons() {
	document.querySelectorAll(".org-src-container").forEach((container) => {
		var pre = container.querySelector("pre.src");
		if (!pre) return;
		var btn = document.createElement("button");
		btn.className = "code-copy-btn";
		btn.textContent = "Copy";
		btn.setAttribute("aria-label", "Copy code to clipboard");
		btn.addEventListener("click", () => {
			var code = pre.textContent;
			navigator.clipboard.writeText(code).then(() => {
				btn.textContent = "Copied!";
				btn.classList.add("copied");
				setTimeout(() => {
					btn.textContent = "Copy";
					btn.classList.remove("copied");
				}, 2000);
			});
		});
		container.appendChild(btn);
	});
}

/* Highlight the current section in the TOC using IntersectionObserver */
function trackActiveSection() {
	var tocLinks = document.querySelectorAll("#text-table-of-contents a");
	if (!tocLinks.length) return;

	/* Build a map from section id to TOC link */
	var linkMap = {};
	tocLinks.forEach((link) => {
		var href = link.getAttribute("href");
		if (href && href.startsWith("#")) {
			linkMap[href.slice(1)] = link;
		}
	});

	/* Collect all heading elements that have TOC entries */
	var headings = [];
	Object.keys(linkMap).forEach((id) => {
		var el = document.getElementById(id);
		if (el) headings.push(el);
	});

	if (!headings.length) return;

	var currentActive = null;

	var observer = new IntersectionObserver(
		(entries) => {
			/* Find the topmost visible heading */
			var visible = [];
			entries.forEach((entry) => {
				if (entry.isIntersecting) {
					visible.push(entry);
				}
			});

			if (visible.length === 0) return;

			visible.sort(
				(a, b) => a.boundingClientRect.top - b.boundingClientRect.top,
			);

			var target = visible[0].target;
			var link = linkMap[target.id];
			if (!link || link === currentActive) return;

			if (currentActive) currentActive.classList.remove("active");
			link.classList.add("active");
			currentActive = link;

			/* Scroll TOC to keep active link visible */
			var toc = document.getElementById("table-of-contents");
			if (toc) {
				var linkRect = link.getBoundingClientRect();
				var tocRect = toc.getBoundingClientRect();
				if (linkRect.top < tocRect.top || linkRect.bottom > tocRect.bottom) {
					link.scrollIntoView({ block: "center", behavior: "smooth" });
				}
			}
		},
		{ rootMargin: "0px 0px -70% 0px", threshold: 0 },
	);

	headings.forEach((h) => {
		observer.observe(h);
	});
}
