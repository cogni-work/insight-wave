import {chromium} from 'playwright';
import fs from 'node:fs/promises';
const browser=await chromium.launch({headless:true,executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'});
const page=await browser.newPage({viewport:{width:1280,height:720},deviceScaleFactor:1});await page.goto('file:///tmp/pr2027-shared/index.html');await page.evaluate(()=>document.fonts.ready);await fs.mkdir('/tmp/pr2027-shared/captures',{recursive:true});
const locators=['#document',...Array.from({length:8},(_,i)=>'#u-slide-'+(i+1))];
const sizes=[];for(const [i,q] of locators.entries()){const el=page.locator(q);await el.screenshot({path:'/tmp/pr2027-shared/captures/unit-'+i+'.png'});sizes.push({unit:q,width:(await el.boundingBox()).width,height:(await el.boundingBox()).height});}
await fs.writeFile('/tmp/pr2027-shared/captures/capture.json',JSON.stringify({tool:'Chrome via Playwright',version:browser.version(),sizes},null,2));await browser.close();
