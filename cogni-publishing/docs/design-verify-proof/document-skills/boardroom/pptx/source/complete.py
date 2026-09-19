import json,zipfile,re
from defusedxml import minidom
from xml.sax.saxutils import escape
from pathlib import Path
B=Path('/tmp/pr2027-document-build'); meta=json.loads((B/'meta.json').read_text());brief=json.load(open('/tmp/pr2027-shared/brief.json'));sources={x['marker']:x['url'] for x in brief['sources']}
A='http://schemas.openxmlformats.org/drawingml/2006/main';P='http://schemas.openxmlformats.org/presentationml/2006/main';R='http://schemas.openxmlformats.org/officeDocument/2006/relationships'
def find(n,t):return n.getElementsByTagName(t)
def el(d,t,attrs={}):
 x=d.createElement(t)
 for k,v in attrs.items():x.setAttribute(k,str(v))
 return x
with zipfile.ZipFile(B/'raw.pptx') as z:parts={n:z.read(n) for n in z.namelist()}
for i,m in enumerate(meta,1):
 path=f'ppt/slides/slide{i}.xml';d=minidom.parseString(parts[path]);find(d,'p:cSld')[0].setAttribute('name',m['name'])
 for bg in find(d,'p:bgPr'):
  if not find(bg,'a:effectLst'):bg.appendChild(el(d,'a:effectLst'))
 names={find(s,'p:cNvPr')[0].getAttribute('name'):s for s in find(d,'p:sp')}
 u=m.get('unit',{})
 for e in u.get('entities',[]):
  name=f"copy:{e['record_ref']}#{e['field']}#{e['item']}";find(names[name],'p:cNvSpPr')[0].removeAttribute('txBox') if find(names[name],'p:cNvSpPr')[0].hasAttribute('txBox') else None
 ids={e['id']:find(names[f"copy:{e['record_ref']}#{e['field']}#{e['item']}"],'p:cNvPr')[0].getAttribute('id') for e in u.get('entities',[])}
 for rel in u.get('relationships',[]):
  s=names[f"connector:{rel['from']}:{rel['to']}"];s.tagName='p:cxnSp';s.nodeName='p:cxnSp';nv=find(s,'p:nvSpPr')[0];nv.tagName='p:nvCxnSpPr';nv.nodeName='p:nvCxnSpPr';pr=find(s,'p:cNvSpPr')[0];pr.tagName='p:cNvCxnSpPr';pr.nodeName='p:cNvCxnSpPr';pr.appendChild(el(d,'a:stCxn',{'id':ids[rel['from']],'idx':1 if u.get('variant')=='cluster' and rel['from']=='e3' else 3}));pr.appendChild(el(d,'a:endCxn',{'id':ids[rel['to']],'idx':3 if u.get('variant')=='cluster' and rel['from']=='e3' else 1}))
 for pr in find(d,'a:rPr'):
  if find(pr,'a:hlinkClick'):
   for f in list(find(pr,'a:solidFill')):pr.removeChild(f)
   f=el(d,'a:solidFill');f.appendChild(el(d,'a:srgbClr',{'val':'FFFFFF' if m['dark'] else '12305C'}));pr.insertBefore(f,pr.firstChild)
 parts[path]=d.toxml(encoding='UTF-8')
 npath=f'ppt/notesSlides/notesSlide{i}.xml';nd=minidom.parseString(parts[npath]);rp=f'ppt/notesSlides/_rels/notesSlide{i}.xml.rels';rd=minidom.parseString(parts[rp]);root=rd.documentElement
 for s in find(nd,'p:sp'):
  ph=find(s,'p:ph')
  if not ph or ph[0].getAttribute('type')!='body':continue
  if not m.get('notes'):s.parentNode.removeChild(s);continue
  find(s,'p:cNvPr')[0].setAttribute('name','notes:'+m['name']);body=find(s,'p:txBody')[0]
  for x in list(body.childNodes):body.removeChild(x)
  body.appendChild(el(nd,'a:bodyPr'));body.appendChild(el(nd,'a:lstStyle'))
  for paragraph in m.get('notes',[]):
   para=el(nd,'a:p');body.appendChild(para)
   for text in re.split(r'(\[\d+\])',paragraph):
    if not text:continue
    run=el(nd,'a:r');pr=el(nd,'a:rPr',{'lang':'de-DE','sz':'1200'});run.appendChild(pr)
    if text in sources:
     rid='rIdNotes'+str(len(find(rd,'Relationship'))+1);root.appendChild(el(rd,'Relationship',{'Id':rid,'Type':R+'/hyperlink','Target':sources[text],'TargetMode':'External'}));pr.appendChild(el(nd,'a:hlinkClick',{'r:id':rid}))
    t=el(nd,'a:t');t.appendChild(nd.createTextNode(text));run.appendChild(t);para.appendChild(run)
 parts[npath]=nd.toxml(encoding='UTF-8');parts[rp]=rd.toxml(encoding='UTF-8')
d=minidom.parseString(parts['[Content_Types].xml'])
for x in list(find(d,'Override')):
 if x.getAttribute('PartName').lstrip('/') not in parts:x.parentNode.removeChild(x)
parts['[Content_Types].xml']=d.toxml(encoding='UTF-8')
with zipfile.ZipFile(B/'deck.pptx','w',zipfile.ZIP_DEFLATED) as z:
 for n,data in parts.items():z.writestr(n,data)
