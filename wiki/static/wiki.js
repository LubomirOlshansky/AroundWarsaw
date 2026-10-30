// The Around Warsaw design wiki: the page filter (hides table rows, cards and lines that don't
// match) and the search page (reads /search.json). No cookies, nothing sent anywhere.
(function () {
  const norm = (s) => s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/ł/g, "l");
  document.querySelectorAll("input.filter").forEach((box) => {
    box.addEventListener("input", () => {
      const q = norm(box.value.trim());
      document.querySelectorAll("main tbody tr, main .cards .card.lm, main section.sys, main ul.lines li").forEach((el) => {
        el.classList.toggle("hidden", q !== "" && !norm(el.textContent).includes(q));
      });
      if (q) document.querySelectorAll("main details").forEach((d) => { if (norm(d.textContent).includes(q)) d.open = true; });
    });
  });
  const results = document.getElementById("results");
  if (!results) return;
  const q = new URLSearchParams(location.search).get("q") || "";
  const input = document.querySelector(".search input");
  if (input) input.value = q;
  if (!q.trim()) return;
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  fetch("/search.json").then((r) => r.json()).then((pages) => {
    const terms = norm(q).split(/\s+/).filter(Boolean);
    const hits = [];
    for (const p of pages) {
      const text = norm(p.text);
      if (!terms.every((t) => text.includes(t) || norm(p.title).includes(t))) continue;
      let score = 0, at = -1;
      for (const t of terms) { let i = text.indexOf(t); if (at < 0) at = i; while (i >= 0) { score++; i = text.indexOf(t, i + 1); } }
      if (norm(p.title).includes(terms[0])) score += 50;
      const start = Math.max(0, at - 80);
      let snip = esc(p.text.slice(start, start + 240));
      hits.push({ p, score, snip });
    }
    hits.sort((a, b) => b.score - a.score);
    results.innerHTML = hits.length
      ? `<p class="small">${hits.length} pages mention “${esc(q)}”.</p>` + hits.map((h) =>
          `<div class="hit"><a href="${h.p.url}"><b>${esc(h.p.title)}</b></a><p>…${h.snip}…</p></div>`).join("")
      : `<p>Nothing mentions “${esc(q)}”.</p>`;
  });
})();
