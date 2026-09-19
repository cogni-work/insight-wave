import zipfile,json,re,copy
from pathlib import Path
from lxml import etree as E
D=Path('/tmp/pr2027-openai-build');meta=json.loads((D/'metadata.json').read_text());brief=json.loads(Path('/tmp/pr2027-shared/brief.json').read_text());sources={s['marker']:s['url'] for s in brief['sources']}
A='http://schemas.openxmlformats.org/drawingml/2006/main';P='http://schemas.openxmlformats.org/presentationml/2006/main';R='http://schemas.openxmlformats.org/officeDocument/2006/relationships';REL='http://schemas.openxmlformats.org/package/2006/relationships';ns={'a':A,'p':P}
with zipfile.ZipFile(D/'candidate.pptx') as z:parts={n:z.read(n) for n in z.namelist()}
for i,m in enumerate(meta,1):
 part=f'ppt/slides/slide{i}.xml';root=E.fromstring(parts[part]);root.find('{'+P+'}cSld').set('name',m['name'])
 for sp in root.findall('.//p:sp',ns):
  prop=sp.find('.//p:cNvPr',ns)
  if prop is not None and prop.get('name','').endswith('#evidence_status'):
   for rpr in sp.findall('.//a:rPr',ns):rpr.set('cap','all')
 parts[part]=E.tostring(root,xml_declaration=True,encoding='UTF-8',standalone=True)
 note=f'ppt/notesSlides/notesSlide{i}.xml'
 if note not in parts:continue
 root=E.fromstring(parts[note]); relpath=f'ppt/notesSlides/_rels/notesSlide{i}.xml.rels';rels=E.fromstring(parts[relpath]);counter=100
 for sp in root.findall('.//p:sp',ns):
  ph=sp.find('.//p:ph',ns)
  if ph is None or ph.get('type')!='body':continue
  body=sp.find('p:txBody',ns)
  for para in list(body.findall('a:p',ns)):body.remove(para)
  for t in m['notes']:
   para=E.SubElement(body,'{'+A+'}p')
   for seg in filter(None,re.split(r'(\[\d+\])',t)):
    run=E.SubElement(para,'{'+A+'}r');pr=E.SubElement(run,'{'+A+'}rPr',sz='1200');E.SubElement(pr,'{'+A+'}latin',typeface='Arial')
    if seg in sources:
     rid=f'rIdProof{counter}';counter+=1
     E.SubElement(pr,'{'+A+'}hlinkClick',{'{'+R+'}id':rid})
     E.SubElement(rels,'{'+REL+'}Relationship',Id=rid,Type=R+'/hyperlink',Target=sources[seg],TargetMode='External')
    E.SubElement(run,'{'+A+'}t').text=seg
 parts[note]=E.tostring(root,xml_declaration=True,encoding='UTF-8',standalone=True);parts[relpath]=E.tostring(rels,xml_declaration=True,encoding='UTF-8',standalone=True)
root=E.fromstring(parts['[Content_Types].xml'])
E.SubElement(root,'{http://schemas.openxmlformats.org/package/2006/content-types}Override',PartName='/docProps/core.xml',ContentType='application/vnd.openxmlformats-package.core-properties+xml')
parts['[Content_Types].xml']=E.tostring(root,xml_declaration=True,encoding='UTF-8',standalone=True)
with zipfile.ZipFile(D/'deck.pptx','w',zipfile.ZIP_DEFLATED) as z:
 for n,v in parts.items():z.writestr(n,v)
