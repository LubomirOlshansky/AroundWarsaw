// The Around Warsaw design wiki (wiki.aroundwarsaw.app): serves build/wiki, the pages
// tools/wiki_build.py makes. It is open to anyone with the link (the user's call, 2026-10-31).
// To lock it again, set the Worker secret WIKI_PASSWORD (`npx wrangler@4 secret put
// WIKI_PASSWORD`): then it asks for HTTP Basic auth, any user name. Every answer asks search
// engines to keep away: the wiki is spoilers and plans, so it stays out of search results.

const PRIVATE = {
  "X-Robots-Tag": "noindex, nofollow, noarchive",
  "Referrer-Policy": "no-referrer",
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
};

async function digest(text) {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text)));
}

async function allowed(request, password) {
  const header = request.headers.get("Authorization") || "";
  const [scheme, encoded] = header.split(" ");
  if (scheme !== "Basic" || !encoded) return false;
  let given;
  try {
    const decoded = new TextDecoder().decode(Uint8Array.from(atob(encoded), (c) => c.charCodeAt(0)));
    given = decoded.slice(decoded.indexOf(":") + 1);
  } catch {
    return false;
  }
  // Compare digests (equal length) in constant time.
  return crypto.subtle.timingSafeEqual(await digest(given), await digest(password));
}

export default {
  async fetch(request, env) {
    if (env.WIKI_PASSWORD && !(await allowed(request, env.WIKI_PASSWORD))) {
      return new Response("Around Warsaw design wiki: sign in.", {
        status: 401,
        headers: { ...PRIVATE, "WWW-Authenticate": 'Basic realm="Around Warsaw design wiki", charset="UTF-8"' },
      });
    }
    const response = await env.ASSETS.fetch(request);
    const headers = new Headers(response.headers);
    for (const [k, v] of Object.entries(PRIVATE)) headers.set(k, v);
    return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
  },
};
