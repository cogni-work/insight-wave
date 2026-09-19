import fs from 'node:fs/promises';
import {FileBlob,PresentationFile} from '@oai/artifact-tool';
import {finalizePresentation} from '/Users/stephandehaas/.codex/plugins/cache/openai-primary-runtime/presentations/26.909.22227/skills/presentations/container_tools/artifact_tool_utils.mjs';
const d='/tmp/pr2027-openai-build';const skill='/Users/stephandehaas/.codex/plugins/cache/openai-primary-runtime/presentations/26.909.22227/skills/presentations';
await fs.mkdir(d+'/final',{recursive:true});
const result=await finalizePresentation({explicitTotalSlideCount:9,requiredNativeTableOwnerSlides:[],requiredNativeChartOwnerSlides:[],workspaceDir:d,candidatePath:d+'/deck.pptx',finalPath:d+'/final/deck-v5.pptx',pythonExecutable:'/Users/stephandehaas/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3',integrityValidatorPath:skill+'/container_tools/inspect_presentation_package_integrity.py',layoutValidatorPath:skill+'/container_tools/inspect_presentation_layout_geometry.py',layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit'],fontPolicy:{basis:'design',families:['Arial']},verifyArtifactToolImport:true,receiptPath:d+'/validation-v5.json'});
console.log(JSON.stringify(result));
const p=await PresentationFile.importPptx(await FileBlob.load(d+'/final/deck-v5.pptx'));
for(const [i,s]of p.slides.items.entries()){const b=await p.export({slide:s,format:'png',scale:1});await fs.writeFile(d+'/previews/final-'+(i+1)+'.png',new Uint8Array(await b.arrayBuffer()));}
const all=await p.export({format:'webp',montage:true,scale:1});await fs.writeFile(d+'/overview.webp',new Uint8Array(await all.arrayBuffer()));
