// Around Warsaw on the web (tools/export_web.sh): Cloudflare serves files of at most 25 MiB, and
// the game's index.pck (~140 MB) and index.wasm (~40 MB) are bigger. The export script gzips each
// and cuts it into parts with a manifest (<name>.parts.json); this wraps fetch so the Godot loader,
// asking for <name>, gets the parts joined and unzipped as one stream, with the whole size as its
// Content-Length (the loading bar). Anything else is fetched as usual.
(function () {
	'use strict';
	const SPLIT = /(^|\/)index\.(pck|wasm)(\?.*)?$/;
	const plainFetch = window.fetch.bind(window);
	window.fetch = function (input, init) {
		const url = typeof input === 'string' ? input : (input instanceof URL ? input.href : input.url);
		if (!SPLIT.test(url) || typeof DecompressionStream === 'undefined') {
			return plainFetch(input, init);
		}
		const base = url.replace(/\?.*$/, '');
		return plainFetch(base + '.parts.json').then(function (r) {
			if (!r.ok) {
				return plainFetch(input, init); // not split (a local test of the plain export)
			}
			return r.json().then(function (m) {
				const dir = base.slice(0, base.lastIndexOf('/') + 1);
				let i = 0;
				let reader = null;
				const body = new ReadableStream({
					async pull(controller) {
						for (;;) {
							if (reader === null) {
								if (i >= m.parts.length) {
									controller.close();
									return;
								}
								const part = await plainFetch(dir + m.parts[i++]);
								if (!part.ok) {
									throw new Error('split_loader: ' + m.parts[i - 1] + ' ' + part.status);
								}
								reader = part.body.getReader();
							}
							const step = await reader.read();
							if (step.done) {
								reader = null;
								continue;
							}
							controller.enqueue(step.value);
							return;
						}
					},
				});
				// The parts are one gzip stream cut in pieces: join, then unzip.
				return new Response(body.pipeThrough(new DecompressionStream('gzip')), {
					status: 200,
					headers: { 'Content-Type': m.type, 'Content-Length': String(m.size) },
				});
			});
		});
	};
}());
