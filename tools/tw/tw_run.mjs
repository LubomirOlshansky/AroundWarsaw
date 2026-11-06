// Usage: node tw_run.mjs MODEL.js OUT.json  -- runs a Tiny Warsaw build(THREE, kit) module with a
// recording kit and writes its triangles grouped by role (facade, solid, glass) and colour.
import * as THREE from 'three';
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';
const [src, out] = process.argv.slice(2);
const log = { unknownKit: {}, warnings: [] };
const tag = (m, role, color, extra = {}) => { m.userData = { role, color: color ?? '#888888', ...extra }; return m; };
const base = {
  finish: (root) => root,  // their foundation skirts: our ground snap does this
  material: (c) => tag(new THREE.MeshBasicMaterial(), 'solid', c),
  glassMaterial: (c) => tag(new THREE.MeshBasicMaterial(), 'glass', c),
  facadeMaterial: (o) => tag(new THREE.MeshBasicMaterial(), 'facade', o?.wall_color, { facade: o }),
  facadeUV: (g) => { if (!g.attributes.uv) g.setAttribute('uv', new THREE.Float32BufferAttribute(new Float32Array(g.attributes.position.count * 2), 2)); return g; },
};
const kit = new Proxy(base, { get(t, k) {
  if (k in t) return t[k];
  log.unknownKit[k] = (log.unknownKit[k] || 0) + 1;
  return (...a) => { log.warnings.push(`kit.${String(k)} called (stubbed)`); return a.find(x => x?.isObject3D || x?.isBufferGeometry || x?.isMaterial) ?? new THREE.Group(); };
}});
let text = fs.readFileSync(src,'utf8');
const tmp = path.join(path.dirname(out), path.basename(src).replace(/\.js$/, '.mjs'));
fs.writeFileSync(tmp, text);
const mod = await import(url.pathToFileURL(tmp).href);
const t0 = Date.now();
const root = mod.default(THREE, kit);
root.updateMatrixWorld(true);
const groups = {};
let tris = 0, meshes = 0;
root.traverse((o) => {
  if (!o.isMesh) return;
  meshes++;
  let g = o.geometry.index ? o.geometry.toNonIndexed() : o.geometry;
  g = g.clone().applyMatrix4(o.matrixWorld);
  const pos = g.attributes.position.array;
  const mats = Array.isArray(o.material) ? o.material : [o.material];
  const ranges = g.groups.length ? g.groups : [{ start: 0, count: pos.length / 3, materialIndex: 0 }];
  for (const r of ranges) {
    const m = mats[r.materialIndex ?? 0] || mats[0];
    const ud = m?.userData ?? { role: 'solid', color: '#888888' };
    const key = `${ud.role}|${ud.color}|${o.name || ''}`;
    const arr = (groups[key] ??= { role: ud.role, color: ud.color, name: o.name || '', facade: ud.facade, v: [] }).v;
    for (let i = r.start * 3; i < (r.start + r.count) * 3; i++) arr.push(+pos[i].toFixed(3));
    tris += r.count / 3;
  }
});
fs.writeFileSync(out, JSON.stringify({ source: path.basename(src), ms: Date.now() - t0, meshes, tris, log, groups: Object.values(groups) }));
console.log(`tw_run: ${path.basename(src)} meshes ${meshes} tris ${tris} groups ${Object.keys(groups).length} unknown kit ${JSON.stringify(log.unknownKit)}`);
