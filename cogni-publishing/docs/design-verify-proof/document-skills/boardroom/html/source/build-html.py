import json,sys,re
from pathlib import Path
from html import escape
root=Path('/Users/stephandehaas/GitHub/dev/insight-wave/.claude/worktrees/i-w-author');sys.path.insert(0,str(root/'cogni-publishing/scripts'));import render_core as core
D=Path('/tmp/pr2027-shared');b=json.loads((D/'brief.json').read_text());c=json.loads((D/'composition.json').read_text());theme=core.resolve_theme(root/'cogni-publishing/themes/boardroom',c['design_system']);lib=json.loads((root/'cogni-publishing/references/pattern-library-v1.json').read_text());patterns={p['id']:p for p in lib['patterns']};rs={r['id']:r for r in b['records']};ss={s['id']:s for s in b['sources']}
def rich(t,hero=False):
 out=''
 for seg in re.split(r'(\[\d+\])',t):
  if re.fullmatch(r'\[\d+\]',seg):
   sid='source-'+seg[1:-1];out+=f'<a data-source="{sid}" href="{escape(ss[sid]["url"],quote=True)}">{seg}</a>'
  else:out+=escape(seg)
 if hero:out=re.sub(r'^(38|19|6,80|31)\b',r'<strong class="hero">\1</strong>',out)
 return out
css='''
/* design-render: components */
body{margin:0;color:var(--colors-text);background:var(--colors-bg);font-family:var(--typography-font-sans)}
header,.canvas{box-sizing:border-box;min-height:720px;padding:60px 70px;position:relative}
header{background:var(--colors-primary);color:var(--colors-bg)}
header h1{font-size:56px;max-width:1100px;margin:100px 0 40px}header p{font-size:30px}
h2{font-size:40px;line-height:1.15;margin:0 0 80px}p{line-height:1.5}
.dark .canvas{background:var(--colors-primary);color:var(--colors-bg)}
.slot-answer h2{font-size:56px}.point{font-size:28px;line-height:1.6;margin:0 0 25px}.hero{font-size:72px;line-height:1}
.entities{display:flex;gap:50px}.entity{width:350px;font-size:26px;line-height:1.4}.entity .hero{font-size:52px}
.relations{display:flex;gap:80px;margin-top:50px;font-size:16px;color:var(--colors-text-muted)}
.evidence{font-size:22px;text-transform:uppercase;margin-top:40px}
a{color:inherit}aside{padding:40px 70px;background:var(--colors-surface);color:var(--colors-text);font-size:16px;line-height:1.6}
.cites{font-size:16px;margin-top:30px}.register li{margin-bottom:25px;font-size:20px;line-height:1.4}.trailer-notes{padding:30px 70px;background:var(--colors-surface)}
'''
h=['<!doctype html><html lang="de"><head><meta charset="utf-8"><title>Nordlicht</title><style>'+theme.css+css+'</style></head><body>']
h+=['<header id="document"><h1 data-copy="document#title">'+rich(b['document']['title'])+'</h1><p data-copy="document#subtitle">'+rich(b['document']['subtitle'])+'</p></header>']
for u in c['units']:
 dark=u['id'] in ('u-slide-1','u-slide-6');h.append(f'<section id="{u["id"]}" data-unit="{u["id"]}" data-pattern="{u["pattern"]}" class="'+('dark' if dark else '')+'"><div class="canvas">')
 order=patterns[u['pattern']]['accessibility']['reading_order'];notes=[]
 for binding in sorted(u['bindings'],key=lambda v:order.index(v['slot'])):
  slot=binding['slot'];key=binding['record_ref']+'#'+binding['field'];r=rs[binding['record_ref']];v=r['headline'] if binding['field']=='headline' else next(f['value'] for f in r['fields'] if f['key']==binding['field'])
  if slot=='notes':notes.append((key,v));continue
  h.append(f'<div data-slot="{slot}" class="slot-{slot}">')
  if binding['field']=='headline':h.append(f'<h2 data-copy="{key}">'+rich(v)+'</h2>')
  elif isinstance(v,list):
   if slot=='entities':h.append('<div class="entities">')
   for i,t in enumerate(v):h.append(f'<p class="'+('entity' if slot=='entities' else 'point')+f'" data-copy="{key}#{i}">'+rich(t,True)+'</p>')
   if slot=='entities':h.append('</div><div class="relations">');h.extend(f'<span data-from="{r["from"]}" data-to="{r["to"]}">{r["kind"]}</span>' for r in u.get('relationships',[]));h.append('</div>' if slot=='entities' else '')
  else:h.append(f'<p class="evidence" data-copy="{key}">'+rich(v)+'</p>')
  h.append('</div>')
 if u.get('register_refs'):
  h.append('<ul class="register">')
  for ref in u['register_refs']:h.append(f'<li data-source="{ref}"><a data-copy="source:{ref}#raw" href="{escape(ss[ref]["url"],quote=True)}">{escape(ss[ref]["raw"])}</a></li>')
  h.append('</ul>')
 h.append('<div class="cites">'+' '.join(f'<a data-source="{ref}" href="{escape(ss[ref]["url"],quote=True)}">{ss[ref]["marker"]}</a>' for ref in u['source_refs'])+'</div></div>')
 if notes:
  h.append('<aside data-slot="notes" class="slot-notes">')
  for key,v in notes:h.append(f'<p data-copy="{key}">'+rich(v)+'</p>')
  h.append('</aside>')
 h.append('</section>')
h.append('<footer class="trailer-notes">')
for binding in c.get('document_bindings',[]):h.append(f'<p data-copy="trailer#{binding["index"]}">'+rich(b['freeze']['trailer_notes'][binding['index']])+'</p>')
h.append('</footer></body></html>');(D/'index.html').write_text('\n'.join(h));(D/'theme-evidence.json').write_text(json.dumps({'tokens':theme.tokens,'sha256':theme.digest,'aliases':{'bg-dark':'colors.primary','text-on-dark':'colors.bg'}},indent=2))
