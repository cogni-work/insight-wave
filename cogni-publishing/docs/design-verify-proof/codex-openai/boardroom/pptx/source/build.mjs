import fs from 'node:fs/promises';
import {Presentation, PresentationFile} from '@oai/artifact-tool';
const dir='/tmp/pr2027-openai-build';
const brief=JSON.parse(await fs.readFile('/tmp/pr2027-shared/brief.json','utf8'));
const comp=JSON.parse(await fs.readFile('/tmp/pr2027-shared/composition.json','utf8'));
const records=Object.fromEntries(brief.records.map(r=>[r.id,r]));
const sources=Object.fromEntries(brief.sources.map(s=>[s.id,s]));
const p=Presentation.create({slideSize:{width:1280,height:720}});
const meta=[];
function runs(text,hero=false){
 const parts=String(text).split(/(\[\d+\])/g);return parts.filter(Boolean).map((t,i)=>{
 const r={run:t}; if(/^\[\d+\]$/.test(t)){r.link={uri:sources['source-'+t.slice(1,-1)].url,isExternal:true};}
 return r;
 });
}
function textbox(s,name,value,x,y,w,h,size,color,bold=false,hero=false){
 const a=s.shapes.add({geometry:'textbox',name,position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});
 a.text=(Array.isArray(value)?value:[value]).map(t=>({runs:runs(t),spaceAfter:1500}));
 a.text.style={typeface:'Arial',fontSize:size,color,bold,autoFit:'none',verticalAlignment:'top',insets:{left:0,right:0,top:0,bottom:0}};
 if(hero){for(const t of (Array.isArray(value)?value:[value])){const m=t.match(/^(38|19|6,80|31)\b/);if(m){a.text.get(m[0]).fontSize=hero===true?72:52;a.text.get(m[0]).bold=true;}}}
 return a;
}
let s=p.slides.add();s.background.fill='#12305C';meta.push({name:'document',notes:[]});
textbox(s,'copy:document#title',brief.document.title,70,160,1140,230,56,'#FFFFFF',true);
textbox(s,'copy:document#subtitle',brief.document.subtitle,70,430,1140,180,30,'#FFFFFF');
for(const u of comp.units){
 const s=p.slides.add();const dark=['u-slide-1','u-slide-6'].includes(u.id);s.background.fill=dark?'#12305C':'#FFFFFF';const ink=dark?'#FFFFFF':'#1A2331';
 const notes=[];const m={name:u.id,notes};meta.push(m);let entities={};
 for(const b of [...u.bindings].sort((a,b)=>(a.field==='evidence_status'?1:0)-(b.field==='evidence_status'?1:0))){
  const r=records[b.record_ref];const v=b.field==='headline'?r.headline:r.fields.find(f=>f.key===b.field).value;const name='copy:'+b.record_ref+'#'+b.field;
  if(b.slot==='notes'){notes.push(...(Array.isArray(v)?v:[v]));continue;}
  if(b.field==='headline'){textbox(s,name,v,70,60,1140,170,b.slot==='answer'?56:40,ink,true);}
  else if(b.field==='evidence_status'){textbox(s,name,v,70,640,650,45,22,ink);}
  else if(b.slot==='entities'){
   for(const [i,t] of v.entries()){const pos=u.id==='u-slide-4'?[[460,250,350,130],[70,470,450,130],[760,470,450,130]][i]:[70+i*390,250,350,310];let a=textbox(s,name+'#'+i,t,...pos,26,ink,false,'entity');entities['e'+(i+1)]=a;}
  }else{textbox(s,name,v,70,250,1140,350,28,ink,false,true);}
 }
 for(const [j,r] of (u.relationships??[]).entries()){textbox(s,'kind:'+r.from+':'+r.to,r.kind,70+j*690,u.id==='u-slide-4'?385:570,400,40,16,ink);s.shapes.connect(entities[r.from],entities[r.to],{kind:u.id==='u-slide-4'?'elbow':'straight',fromSide:u.id==='u-slide-4'?'top':'right',toSide:u.id==='u-slide-4'?'bottom':'left',line:{fill:'#828B9E',width:2},tail:{type:'triangle'}});}
 if(u.register_refs){let vals=u.register_refs.map(ref=>sources[ref].raw);textbox(s,'register:'+u.id,vals,70,230,1140,400,20,ink);}
 const cites=(u.source_refs??[]).map(ref=>sources[ref].marker).join(' ');if(cites)textbox(s,'cites:'+u.id,cites,880,645,330,40,16,ink);
 if(u.id===comp.units.at(-1).id)notes.push(...(comp.document_bindings??[]).map(b=>brief.freeze.trailer_notes[b.index]));
 s.speakerNotes.textFrame.setText(notes.join('\n'));
}
await fs.writeFile(dir+'/metadata.json',JSON.stringify(meta,null,2));
await(await PresentationFile.exportPptx(p)).save(dir+'/candidate.pptx');
await fs.mkdir(dir+'/previews',{recursive:true});
for(const [i,s] of p.slides.items.entries()){const b=await p.export({slide:s,format:'png',scale:1});await fs.writeFile(dir+'/previews/slide-'+(i+1)+'.png',new Uint8Array(await b.arrayBuffer()));}
console.log('Created '+p.slides.items.length+' slides from frozen input');
