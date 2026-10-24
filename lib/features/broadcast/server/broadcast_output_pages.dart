const String broadcastManagerHtml = r'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cricket Scorer - Broadcast Manager</title>
<style>
:root{color-scheme:dark;font-family:Segoe UI,Arial,sans-serif;background:#0c1210;color:#f3f6f2}
*{box-sizing:border-box}body{margin:0;padding:24px;max-width:1180px;margin-inline:auto}
h1{font-size:28px;margin:0 0 6px}p{color:#aab8ad;margin:0 0 20px}.status{padding:12px 14px;border:1px solid #34483b;border-radius:10px;margin-bottom:18px;background:#131d17}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}.card{border:1px solid #34483b;border-radius:14px;padding:18px;background:#121a15}
h2{font-size:17px;margin:0 0 14px}.row{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:9px 0;border-bottom:1px solid #28362d}
button{border:1px solid #526b58;background:#213729;color:#f4fff6;border-radius:8px;padding:9px 12px;cursor:pointer;font-weight:600}
button:hover{background:#2b4c37}.danger{background:#52272a;border-color:#794147}
input,textarea,select{font:inherit;color:#fff;background:#0b100d;border:1px solid #435448;border-radius:8px;width:100%;padding:10px;margin:5px 0 12px}
label{display:block;font-size:13px;color:#bdc9bf}.sources button{display:block;width:100%;text-align:left;overflow-wrap:anywhere;margin:8px 0}.muted{font-size:12px;color:#8fa194}.actions{display:flex;flex-wrap:wrap;gap:8px}
.event-media-library{display:grid;gap:10px;margin:10px 0}
.media-asset{border:1px solid #34483b;border-radius:10px;padding:10px;display:grid;grid-template-columns:86px minmax(0,1fr);gap:10px;background:#0d1510}
.media-asset img,.media-asset video{width:86px;height:70px;object-fit:contain;background:#050906;border-radius:6px}
.media-asset .asset-title{font-weight:700;overflow-wrap:anywhere}
.media-asset .asset-actions{display:flex;flex-wrap:wrap;gap:6px;margin-top:8px}
.media-asset .asset-actions button{padding:7px 9px;font-size:12px}
.media-asset select{margin:5px 0 0;padding:7px}

</style></head><body>
<h1>Broadcast Control</h1><p>Management and OBS/vMix browser sources share this local server.</p>
<div class="status" id="status">Connecting to broadcast engine...</div>
<div class="grid">
<section class="card"><h2>Graphic visibility</h2><div id="toggles"></div><div class="actions" style="margin-top:14px"><button id="hideAll" class="danger">Hide all graphics</button><button id="showAll">Show all graphics</button></div></section>
<section class="card"><h2>Compact scorecard style</h2><label for="scorecardStyle">Output style</label><select id="scorecardStyle"><option value="minimal">Minimal</option><option value="detailed">Detailed</option><option value="fullBroadcastBar">Full broadcast bar</option></select><span class="muted">The selection applies to the combined OBS/vMix output.</span></section>
<section class="card"><h2>Full-screen Scorecard</h2><label for="fullScreenView">View</label><select id="fullScreenView"><option value="combined">Combined Batting &amp; Bowling</option><option value="batting">Batting</option><option value="bowling">Bowling</option><option value="playingXi">Playing XI</option></select>
<div class="actions"><button data-full-view="combined">Combined</button><button data-full-view="batting">Batting</button><button data-full-view="bowling">Bowling</button><button data-full-view="playingXi">Playing XI</button></div>
<label for="fullScreenStyle">Layout design</label><select id="fullScreenStyle"><option value="traditional">Traditional Scorecard Table</option><option value="tvBroadcast">TV Broadcast Design</option></select>
<label for="playingXiMode">Playing XI display</label><select id="playingXiMode"><option value="both">Both teams together</option><option value="single">One team at a time</option></select>
<label for="playingXiTeam">Playing XI team (single-team mode)</label><select id="playingXiTeam"><option value="teamA">Team A</option><option value="teamB">Team B</option></select>
<label><input id="fullScreenTransparent" type="checkbox" style="width:auto;margin-right:8px">Transparent background</label>
<label><input id="showCompactScorecard" type="checkbox" style="width:auto;margin-right:8px">Keep compact scorecard visible</label>
<div class="actions"><button id="showFullScreen">Show full-screen</button><button id="hideFullScreen">Return to compact</button></div>
<span class="muted">Manual view selection only. Full-screen output uses the current broadcast innings; it does not rotate automatically.</span></section>
<section class="card"><h2>Copy URLs</h2><div class="sources" id="sources"></div><span class="muted">Use Combined output as one OBS/vMix Browser Source. Keep the Manager URL separate for controls.</span></section>
<section class="card"><h2>Manual ticker</h2><label for="ticker">Message (max 280 characters)</label><textarea id="ticker" rows="3" maxlength="280"></textarea><label for="tickerDuration">Duration (seconds)</label><input id="tickerDuration" type="number" min="1" max="120" value="12"><div class="actions"><button id="sendTicker">Send ticker</button><button data-clear="ticker">Clear ticker</button></div></section>
<section class="card"><h2>Event graphic</h2><label><input id="autoEventPlayback" type="checkbox" style="width:auto;margin-right:8px">Enable automatic event playback</label><div class="muted">Assigned FOUR, SIX and WICKET media automatically play for new live scoring events.</div><label for="eventDetail">Optional player/detail text</label><input id="eventDetail" maxlength="180" placeholder="Batter or short message">
<div class="actions"><button data-event="FOUR">FOUR</button><button data-event="SIX">SIX</button><button data-event="WICKET" class="danger">WICKET</button><button data-event="CUSTOM_1">Custom Event 1</button><button data-event="CUSTOM_2">Custom Event 2</button><button data-event="CUSTOM_3">Custom Event 3</button></div>
<label for="eventSlot">Configure media for</label><select id="eventSlot"><option value="FOUR">FOUR</option><option value="SIX">SIX</option><option value="WICKET">WICKET</option><option value="CUSTOM_1">Custom Event 1</option><option value="CUSTOM_2">Custom Event 2</option><option value="CUSTOM_3">Custom Event 3</option></select>
<label for="customEventName">Custom event name (Custom slots only)</label><input id="customEventName" maxlength="48" placeholder="e.g. Super Over">
<label for="eventCategory">Media category</label><select id="eventCategory"><option value="FOUR">FOUR</option><option value="SIX">SIX</option><option value="WICKET">WICKET</option><option value="Custom Events" selected>Custom Events</option><option value="Team Logos">Team Logos</option><option value="Sponsors">Sponsors</option></select>
<label for="eventMediaFile">Picture / animation / video (PNG, JPG, GIF, WebP, APNG, MP4, WebM · max 50 MB)</label><input id="eventMediaFile" type="file" accept=".png,.jpg,.jpeg,.gif,.webp,.apng,.mp4,.webm">
<label for="eventDuration">On-air duration (seconds)</label><input id="eventDuration" type="number" min="1" max="120" value="5">
<label><input id="eventLoop" type="checkbox" style="width:auto;margin-right:8px">Loop video until event duration expires</label>
<div class="actions"><button id="uploadEventMedia">Choose & upload</button><button id="saveEventSettings">Save settings</button><button id="previewEventMedia">Preview</button><button id="clearEventMedia">Clear assignment</button><button id="playEventOnAir">Play On Air</button><button id="replayEvent">Replay</button></div>
<div id="eventMediaStatus" class="muted" style="margin-top:8px">Select a slot to configure its media.</div>
<div class="actions" style="margin-top:12px"><button id="refreshEventLibrary">Refresh media library</button></div>
<label for="eventLibrarySearch">Search reusable media</label><input id="eventLibrarySearch" type="search" placeholder="Name, category or assigned event">
<label for="eventLibraryFilter">Filter by category</label><select id="eventLibraryFilter"><option value="All categories">All categories</option><option value="FOUR">FOUR</option><option value="SIX">SIX</option><option value="WICKET">WICKET</option><option value="Custom Events">Custom Events</option><option value="Team Logos">Team Logos</option><option value="Sponsors">Sponsors</option></select>
<div id="eventMediaLibrary" class="event-media-library"><span class="muted">Start Broadcasting and refresh to load reusable assets.</span></div>
<div id="eventMediaPreview" style="display:none;margin-top:10px;padding:10px;background:#0b100d;border-radius:8px"><img id="eventPreviewImage" alt="Event media preview" style="display:none;max-width:100%;max-height:260px;object-fit:contain"><video id="eventPreviewVideo" controls muted playsinline style="display:none;max-width:100%;max-height:260px"></video></div>
<div style="margin-top:12px"><button data-clear="event">Clear event</button><button data-clear="messages">Clear all messages</button></div>
<span class="muted">AVI is not reliably supported by OBS/vMix browser sources; convert AVI clips to MP4 (H.264). Preview does not put graphics on air.</span></section>
<section class="card"><h2>Player lower-third</h2><label for="lowerTitle">Title</label><input id="lowerTitle" maxlength="80" placeholder="Player name"><label for="lowerDetail">Detail</label><input id="lowerDetail" maxlength="180" placeholder="48 off 32 balls - Kings"><label for="lowerDuration">Duration (seconds)</label><input id="lowerDuration" type="number" min="1" max="120" value="8"><div class="actions"><button id="sendLower">Show lower-third</button><button data-clear="lowerThird">Clear</button></div></section>
</div>
<script>
const names={scorecard:'Scorecard',ticker:'Ticker',lowerThird:'Lower third',lastBall:'Last-ball/event'};
const paths=['broadcast/output','broadcast/manage'];
function makeSourceLinks(){const root=document.getElementById('sources');for(const path of paths){const b=document.createElement('button');b.textContent=location.origin+'/'+path;b.onclick=async()=>{const url=location.origin+'/'+path;try{await navigator.clipboard.writeText(url);statusText('Copied '+url);}catch(_){window.prompt('Copy browser-source URL',url);}};root.appendChild(b);}}
function statusText(text){document.getElementById('status').textContent=text;}
async function api(path,body){const r=await fetch(path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});if(!r.ok)throw new Error(await r.text());await refresh();}
let fullScreenCurrentlyEnabled=false;
async function refresh(){try{const r=await fetch('/api/v1/broadcast/state',{cache:'no-store'});if(!r.ok)throw new Error('State request failed');const s=await r.json();eventMediaState=s.eventMediaSettings||{};const autoPlayback=document.getElementById('autoEventPlayback');if(document.activeElement!==autoPlayback)autoPlayback.checked=s.automaticEventPlaybackEnabled!==false;const m=s.snapshot;const styleSelect=document.getElementById('scorecardStyle');if(document.activeElement!==styleSelect){styleSelect.value=s.scorecardStyle||'fullBroadcastBar';}const fs=s.fullScreenScorecardSettings||{};fullScreenCurrentlyEnabled=fs.enabled===true;const fsControls=['fullScreenView','fullScreenStyle','playingXiMode','playingXiTeam','fullScreenTransparent','showCompactScorecard'];if(!fsControls.includes(document.activeElement?.id)){document.getElementById('fullScreenView').value=fs.view||'combined';document.getElementById('fullScreenStyle').value=fs.style||'traditional';document.getElementById('playingXiMode').value=fs.playingXiMode||'both';document.getElementById('playingXiTeam').value=fs.playingXiTeam||'teamA';document.getElementById('fullScreenTransparent').checked=fs.transparent===true;document.getElementById('showCompactScorecard').checked=fs.showCompactScorecard===true;}if(eventSlotLoaded!==selectedEventSlot())loadEventSlot();statusText(m&&m.ready?'Snapshot ready - '+(m.matchName||'Match')+' - '+m.oversText+' overs':'Server ready - waiting for a live match or scoring data.');const host=document.getElementById('toggles');host.replaceChildren();for(const key of Object.keys(names)){const row=document.createElement('div');row.className='row';const label=document.createElement('span');label.textContent=names[key];const button=document.createElement('button');button.textContent=s.overlays[key]?'ON':'OFF';button.onclick=()=>api('/api/v1/broadcast/overlay',{overlay:key,enabled:!s.overlays[key]}).catch(e=>statusText(e.message));row.append(label,button);host.appendChild(row);}}catch(e){statusText('Broadcast server unavailable: '+e.message);}}
document.getElementById('scorecardStyle').onchange=()=>api('/api/v1/broadcast/scorecard-style',{style:document.getElementById('scorecardStyle').value}).catch(e=>statusText(e.message));
function fullScreenSettingsPayload(enabled){return{enabled:enabled,view:document.getElementById('fullScreenView').value,style:document.getElementById('fullScreenStyle').value,transparent:document.getElementById('fullScreenTransparent').checked,showCompactScorecard:document.getElementById('showCompactScorecard').checked,playingXiMode:document.getElementById('playingXiMode').value,playingXiTeam:document.getElementById('playingXiTeam').value};}
async function updateFullScreenScorecard(enabled){try{await api('/api/v1/broadcast/full-screen-scorecard',fullScreenSettingsPayload(enabled));statusText(enabled?'Full-screen scorecard is on air.':'Returned to compact graphics.');}catch(e){statusText('Unable to update full-screen scorecard: '+e.message);}}
document.getElementById('showFullScreen').onclick=()=>updateFullScreenScorecard(true);
document.getElementById('hideFullScreen').onclick=()=>updateFullScreenScorecard(false);
for(const id of ['fullScreenView','fullScreenStyle','playingXiMode','playingXiTeam','fullScreenTransparent','showCompactScorecard'])document.getElementById(id).onchange=()=>updateFullScreenScorecard(fullScreenCurrentlyEnabled);
document.querySelectorAll('button[data-full-view]').forEach(button=>button.onclick=()=>{document.getElementById('fullScreenView').value=button.dataset.fullView;updateFullScreenScorecard(true);});
document.getElementById('hideAll').onclick=()=>api('/api/v1/broadcast/overlays',{enabled:false}).catch(e=>statusText(e.message));
document.getElementById('showAll').onclick=()=>api('/api/v1/broadcast/overlays',{enabled:true}).catch(e=>statusText(e.message));
document.getElementById('sendTicker').onclick=()=>api('/api/v1/broadcast/ticker',{text:document.getElementById('ticker').value,durationSeconds:Number(document.getElementById('tickerDuration').value)}).catch(e=>statusText(e.message));
document.getElementById('autoEventPlayback').onchange=()=>api('/api/v1/broadcast/event-playback',{enabled:document.getElementById('autoEventPlayback').checked}).then(()=>statusText('Automatic event playback setting saved.')).catch(e=>statusText(e.message));
const eventSlots={FOUR:'FOUR',SIX:'SIX',WICKET:'WICKET',CUSTOM_1:'Custom Event 1',CUSTOM_2:'Custom Event 2',CUSTOM_3:'Custom Event 3'};
let eventMediaState={},eventMediaPreviewOn=false,eventSlotLoaded='';
function selectedEventSlot(){return document.getElementById('eventSlot').value;}
function eventSlotValues(){return eventMediaState[selectedEventSlot()]||{};}
function loadEventSlot(){const value=eventSlotValues();const slot=selectedEventSlot();eventSlotLoaded=slot;const custom=slot.startsWith('CUSTOM_');const name=document.getElementById('customEventName');name.value=value.name||eventSlots[slot];name.disabled=!custom;document.getElementById('eventDuration').value=value.durationSeconds||5;document.getElementById('eventLoop').checked=value.loop===true;document.getElementById('eventMediaFile').value='';eventMediaPreviewOn=false;document.getElementById('eventMediaPreview').style.display='none';document.getElementById('eventMediaStatus').textContent=value.mediaName?'Assigned: '+value.mediaName+' · '+(value.durationSeconds||5)+' seconds'+(value.loop?' · loop enabled':''):'No media assigned · text-only event';}
document.getElementById('eventSlot').onchange=loadEventSlot;
const eventMediaCategories=['FOUR','SIX','WICKET','Custom Events','Team Logos','Sponsors'];
let eventLibraryAssets=[];
async function deleteEventAsset(asset){
 const previewResponse=await fetch('/api/v1/broadcast/media/delete',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({mediaId:asset.mediaId})});
 if(previewResponse.status!==409)throw new Error(await previewResponse.text()||'Unable to review media assignments before deletion.');
 const preview=await previewResponse.json();
 if(preview.requiresConfirmation!==true)throw new Error('The server did not return a deletion confirmation summary.');
 const slots=preview.assignedSlots||[];
 const slotsText=slots.length?slots.join(', '):'None — no event slots use this asset.';
 const confirmed=window.confirm('Delete "'+(preview.name||asset.name||asset.mediaId)+'" from the reusable media library?\n\nEvent slots using this asset: '+slotsText+'\n\nConfirming deletes the file and clears those event media assignments. Cancelling changes nothing.');
 if(!confirmed){statusText('Deletion cancelled; media and assignments are unchanged.');return;}
 const response=await fetch('/api/v1/broadcast/media/delete',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({mediaId:asset.mediaId,confirm:true,expectedAssignedSlots:slots})});
 const result=await response.json().catch(()=>({}));
 if(response.status===409){await refreshEventLibrary();throw new Error((result.message||'Event assignments changed before deletion.')+' Refresh the list and review the current assignments.');}
 if(!response.ok)throw new Error(result.message||'Unable to delete media asset.');
 const stateResponse=await fetch('/api/v1/broadcast/state',{cache:'no-store'});
 if(stateResponse.ok){const state=await stateResponse.json();eventMediaState=state.eventMediaSettings||{};loadEventSlot();}
 await refreshEventLibrary();
 statusText('Deleted '+(result.name||asset.name||asset.mediaId)+'; cleared '+(result.clearedAssignments||[]).length+' event assignment(s).');
}
function renderEventLibrary(){
 const root=document.getElementById('eventMediaLibrary');if(!root)return;
 const query=(document.getElementById('eventLibrarySearch').value||'').trim().toLowerCase();
 const category=document.getElementById('eventLibraryFilter').value;
 root.replaceChildren();
 const filtered=eventLibraryAssets.filter(asset=>{const text=[asset.name,asset.category,(asset.assignedSlots||[]).join(' ')].join(' ').toLowerCase();return(category==='All categories'||asset.category===category)&&(!query||text.includes(query));});
 if(!filtered.length){const empty=document.createElement('div');empty.className='muted';empty.textContent=eventLibraryAssets.length?'No assets match this search.':'No media uploaded yet. Upload a file above to add one.';root.appendChild(empty);return;}
 for(const asset of filtered){
  const card=document.createElement('div');card.className='media-asset';
  const media=document.createElement(asset.mediaType==='image'?'img':'div');
  if(asset.mediaType==='image'){media.src=asset.url;media.alt=asset.name||'Media preview';}else{media.className='muted';media.textContent='VIDEO';media.style.display='grid';media.style.placeItems='center';}
  const body=document.createElement('div');
  const title=document.createElement('div');title.className='asset-title';title.textContent=asset.name||asset.mediaId;body.appendChild(title);
  const meta=document.createElement('div');meta.className='muted';meta.textContent=(asset.category||'Uncategorized')+' · '+Math.ceil((asset.sizeBytes||0)/1024)+' KB · Assigned: '+((asset.assignedSlots||[]).join(', ')||'none');body.appendChild(meta);
  const categoryLabel=document.createElement('label');categoryLabel.textContent='Category';body.appendChild(categoryLabel);
  const select=document.createElement('select');select.setAttribute('aria-label','Category for '+(asset.name||asset.mediaId));
  for(const value of eventMediaCategories){const option=document.createElement('option');option.value=value;option.textContent=value;option.selected=value===asset.category;select.appendChild(option);}
  body.appendChild(select);
  const actions=document.createElement('div');actions.className='asset-actions';
  const assign=document.createElement('button');assign.textContent='Assign to selected slot';assign.onclick=async()=>{try{const slot=selectedEventSlot();const settings={slot,mediaId:asset.mediaId,mediaName:asset.name,mediaUrl:asset.url,mediaType:asset.mediaType,loop:document.getElementById('eventLoop').checked,durationSeconds:Number(document.getElementById('eventDuration').value)||5};if(slot.startsWith('CUSTOM_'))settings.name=document.getElementById('customEventName').value||eventSlots[slot];await eventSettings(settings);statusText('Assigned '+asset.name+' to '+eventSlots[slot]+'.');}catch(e){statusText('Unable to assign media: '+e.message);}};
  const saveCategory=document.createElement('button');saveCategory.textContent='Save category';saveCategory.onclick=async()=>{try{const r=await fetch('/api/v1/broadcast/media/category',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({mediaId:asset.mediaId,category:select.value})});if(!r.ok)throw new Error(await r.text());await refreshEventLibrary();statusText('Updated category for '+asset.name+'.');}catch(e){statusText('Unable to change category: '+e.message);}};
  const replace=document.createElement('button');replace.textContent='Replace file';replace.onclick=()=>{const input=document.createElement('input');input.type='file';input.accept='.png,.jpg,.jpeg,.gif,.webp,.apng,.mp4,.webm';input.onchange=async()=>{const file=input.files&&input.files[0];if(!file)return;try{statusText('Replacing '+asset.name+'…');const updated=await uploadMediaIntoLibrary(file,asset.mediaId);if(updated){await refreshEventLibrary();statusText('Replaced '+asset.name+'; existing event assignments remain linked.');}}catch(e){statusText('Unable to replace asset: '+e.message);}};input.click();};
  const preview=document.createElement('button');preview.textContent='Preview';preview.onclick=()=>{const wrap=document.getElementById('eventMediaPreview'),image=document.getElementById('eventPreviewImage'),video=document.getElementById('eventPreviewVideo');video.pause();video.removeAttribute('src');image.removeAttribute('src');wrap.style.display='block';if(asset.mediaType==='image'){image.src=asset.url;image.style.display='block';video.style.display='none';}else{video.src=asset.url;video.loop=asset.loop===true;video.style.display='block';image.style.display='none';video.load();video.play().catch(()=>{});}statusText('Preview only — not on air.');};
  const remove=document.createElement('button');remove.textContent='Delete asset';remove.className='danger';remove.onclick=async()=>{try{await deleteEventAsset(asset);}catch(e){statusText('Unable to delete asset: '+e.message);}};
  actions.append(assign,saveCategory,replace,preview,remove);body.appendChild(actions);card.append(media,body);root.appendChild(card);
 }
}
async function refreshEventLibrary(){try{const response=await fetch('/api/v1/broadcast/media/library',{cache:'no-store'});if(!response.ok)throw new Error('Library request failed');const value=await response.json();eventLibraryAssets=value.assets||[];renderEventLibrary();}catch(e){const root=document.getElementById('eventMediaLibrary');if(root){root.textContent='Unable to load media library: '+e.message;}}}
document.getElementById('eventLibrarySearch').oninput=renderEventLibrary;
document.getElementById('eventLibraryFilter').onchange=renderEventLibrary;
document.getElementById('refreshEventLibrary').onclick=()=>refreshEventLibrary();
async function eventSettings(body){const r=await fetch('/api/v1/broadcast/event-settings',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});if(r.status!==204)throw new Error(await r.text()||'Unable to save event settings.');const response=await fetch('/api/v1/broadcast/state',{cache:'no-store'});const state=await response.json();eventMediaState=state.eventMediaSettings||{};loadEventSlot();await refresh();await refreshEventLibrary();}
async function uploadMediaIntoLibrary(file,replaceMediaId){
 if(file.size>50*1024*1024)throw new Error('Media files must be 50 MB or smaller.');
 const makeUrl=(duplicateAction,replaceDuplicateId)=>{const q=new URLSearchParams({name:file.name,category:document.getElementById('eventCategory').value});if(replaceMediaId)q.set('replaceMediaId',replaceMediaId);if(duplicateAction)q.set('duplicateAction',duplicateAction);if(replaceDuplicateId)q.set('replaceDuplicateId',replaceDuplicateId);return '/api/v1/broadcast/media/upload?'+q.toString();};
 let response=await fetch(makeUrl(),{method:'POST',headers:{'Content-Type':file.type||'application/octet-stream'},body:file});
 if(response.status===409){
  const conflict=await response.json(),existing=conflict.existing||{};
  const replace=window.confirm('Identical content already exists as "'+(existing.name||existing.mediaId)+'" in '+(existing.category||'the media library')+'. Press OK to update that library entry and use it; Cancel skips the duplicate. Existing event assignments stay linked.');
  if(!replace){await refreshEventLibrary();statusText('Duplicate skipped; media library unchanged.');return null;}
  response=await fetch(makeUrl('replace',existing.mediaId),{method:'POST',headers:{'Content-Type':file.type||'application/octet-stream'},body:file});
 }
 if(response.status!==201&&response.status!==200)throw new Error(await response.text());
 return await response.json();
}
document.getElementById('uploadEventMedia').onclick=async()=>{const file=document.getElementById('eventMediaFile').files[0];if(!file){statusText('Choose a picture, GIF or video file first.');return;}try{statusText('Uploading '+file.name+'…');const uploaded=await uploadMediaIntoLibrary(file,null);if(!uploaded)return;await refreshEventLibrary();if(uploaded.skipped){statusText('Duplicate skipped.');return;}const slot=selectedEventSlot();const body={slot,mediaId:uploaded.mediaId,mediaName:uploaded.name,mediaUrl:uploaded.url,mediaType:uploaded.mediaType,loop:document.getElementById('eventLoop').checked,durationSeconds:Number(document.getElementById('eventDuration').value)||5};if(slot.startsWith('CUSTOM_'))body.name=document.getElementById('customEventName').value||eventSlots[slot];await eventSettings(body);statusText('Uploaded and assigned '+file.name+'.');}catch(e){statusText('Media upload failed: '+e.message);}};
document.getElementById('saveEventSettings').onclick=async()=>{try{const slot=selectedEventSlot();const body={slot,loop:document.getElementById('eventLoop').checked,durationSeconds:Number(document.getElementById('eventDuration').value)||5};if(slot.startsWith('CUSTOM_'))body.name=document.getElementById('customEventName').value||eventSlots[slot];await eventSettings(body);statusText('Saved '+eventSlots[slot]+' settings.');}catch(e){statusText('Unable to save settings: '+e.message);}};
document.getElementById('clearEventMedia').onclick=async()=>{try{const slot=selectedEventSlot();await eventSettings({slot,clearMedia:true});statusText('Cleared media assignment for '+eventSlots[slot]+'.');}catch(e){statusText('Unable to clear media: '+e.message);}};
document.getElementById('previewEventMedia').onclick=()=>{const value=eventSlotValues();if(!value.mediaUrl){statusText('Upload media for this slot first.');return;}const host=document.getElementById('eventMediaPreview'),image=document.getElementById('eventPreviewImage'),video=document.getElementById('eventPreviewVideo');video.pause();video.removeAttribute('src');image.removeAttribute('src');host.style.display='block';if(value.mediaType==='image'){image.src=value.mediaUrl;image.style.display='block';video.style.display='none';}else{video.src=value.mediaUrl;video.loop=value.loop===true;video.style.display='block';image.style.display='none';video.load();video.play().catch(()=>{});}eventMediaPreviewOn=true;statusText('Preview only — not on air.');};
document.querySelectorAll('button[data-event]').forEach(b=>b.onclick=()=>{const kind=b.dataset.event;const detail=document.getElementById('eventDetail').value;if(kind==='CUSTOM'&&!detail.trim()){statusText('Enter a custom event message first.');return;}api('/api/v1/broadcast/event',{kind,detail}).catch(e=>statusText(e.message));});
document.getElementById('playEventOnAir').onclick=()=>api('/api/v1/broadcast/event',{kind:selectedEventSlot(),detail:document.getElementById('eventDetail').value}).then(()=>statusText('Event sent on air.')).catch(e=>statusText(e.message));
document.getElementById('replayEvent').onclick=()=>api('/api/v1/broadcast/event',{kind:selectedEventSlot(),detail:document.getElementById('eventDetail').value}).then(()=>statusText('Event replayed.')).catch(e=>statusText(e.message));
document.getElementById('sendLower').onclick=()=>api('/api/v1/broadcast/lower-third',{title:document.getElementById('lowerTitle').value,detail:document.getElementById('lowerDetail').value,durationSeconds:Number(document.getElementById('lowerDuration').value)}).catch(e=>statusText(e.message));
document.querySelectorAll('button[data-clear]').forEach(b=>b.onclick=()=>api('/api/v1/broadcast/clear',{kind:b.dataset.clear}).catch(e=>statusText(e.message)));
makeSourceLinks();refresh();refreshEventLibrary();setInterval(refresh,1500);
</script></body></html>''';

const String broadcastCompositeOutputHtml = r'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cricket Scorer — Combined Broadcast Output</title>
<style>
*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;overflow:hidden;background:transparent;font-family:Segoe UI,Arial,sans-serif;color:#fff}
#canvas{position:relative;width:100vw;height:100vh;overflow:hidden;background:transparent;isolation:isolate}.layer{position:absolute;display:none}
#scorecard{left:3%;top:82.5%;width:94%;height:8%;max-width:none;padding:0;border:0;border-radius:0;background:transparent;box-shadow:none;overflow:visible}
.broadcast-bar{container-type:size;display:grid;grid-template-columns:1.08fr .9fr 1.65fr 1.1fr 1.08fr;width:100%;height:100%;overflow:hidden;border:2px solid #d4e1ed;border-radius:clamp(7px,.7vw,18px);background:#102437;box-shadow:0 9px 28px #0009}
.bar-section{min-width:0;display:flex;flex-direction:column;justify-content:center;padding:2.5cqh .85cqw;overflow:hidden;border-right:1px solid #ffffff32}.bar-section:last-child{border-right:0}
.section-label{font-size:14cqh;font-weight:850;letter-spacing:.08em;text-transform:uppercase;color:#c3d4e3;white-space:nowrap;margin-bottom:.18em}
.team-section{background:linear-gradient(140deg,#1b3a55,#102437)}.team-heading{display:flex;align-items:center;gap:8%;min-width:0}
.team-badge{flex:0 0 auto;display:flex;align-items:center;justify-content:center;width:30cqh;height:30cqh;border-radius:50%;background:#d8b45a;color:#102437;font-size:14cqh;font-weight:1000}
.team-name{min-width:0;font-size:26cqh;font-weight:900;line-height:1.05;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.team-meta{font-size:11cqh;color:#c3d4e3;margin-top:.2em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.score-section{background:linear-gradient(145deg,#d9b552,#b98c2f);color:#142537;align-items:flex-start}.score-section .section-label{color:#314252}
.score-value{font-size:40cqh;line-height:.95;font-weight:1000;white-space:nowrap;letter-spacing:-.04em}.overs-value{font-size:17cqh;font-weight:850;margin-top:.12em;white-space:nowrap}.chase-value{font-size:10cqh;font-weight:800;margin-top:.08em;white-space:nowrap;line-height:1.02;overflow:hidden;text-overflow:ellipsis;max-width:100%}
.batters-section{background:linear-gradient(135deg,#18354c,#0e202f)}.batter-row{display:grid;grid-template-columns:minmax(0,1.4fr) minmax(0,1fr);gap:4%;align-items:center;padding:.12em 0;border-bottom:1px solid #ffffff22}.batter-row:last-child{border-bottom:0}
.batter-name{font-size:20cqh;font-weight:800;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.batter-stats{font-size:15cqh;font-weight:750;white-space:nowrap;text-align:right;color:#dce8f1}.batter-name .strike{color:#e2bd61;margin-right:.25em}
.bowler-section{background:#142d3d}.bowler-name{font-size:22cqh;font-weight:900;line-height:1.02;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.bowler-figures{font-size:25cqh;font-weight:950;margin-top:.1em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.bowler-economy{font-size:11cqh;color:#cedbe5;margin-top:.08em;white-space:nowrap}
.recent-section{background:#0d1b28}.ball-list{display:flex;align-items:center;gap:3%;min-width:0;flex-wrap:wrap}.ball{min-width:30cqh;height:30cqh;padding:0 .2em;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;background:#d8e3eb;color:#142637;font-size:14cqh;font-weight:950}.ball.boundary{background:#55c5bc;color:#082b35}.ball.wicket{background:#df6669;color:#fff}.ball.extra{background:#e2bd61;color:#172b3d}.empty-state{font-size:14cqh;color:#c3d4e3}
#scorecard[data-style="minimal"] .broadcast-bar{grid-template-columns:1.1fr .9fr}#scorecard[data-style="minimal"] .batters-section,#scorecard[data-style="minimal"] .bowler-section,#scorecard[data-style="minimal"] .recent-section{display:none}
#scorecard[data-style="detailed"] .broadcast-bar{grid-template-columns:1.05fr .9fr 1.5fr 1fr}#scorecard[data-style="detailed"] .recent-section{display:none}
#ticker{left:3%;top:91.5%;width:94%;height:6.5%;right:auto;bottom:auto;min-height:0;align-items:center;background:#08140ff2;border-left:clamp(5px,.45vw,16px) solid #a8d28b;border-radius:clamp(5px,.5vw,16px);overflow:hidden;box-shadow:0 7px 25px #0007}
#tickerLabel{height:100%;display:flex;align-items:center;padding:0 1.5%;background:#a8d28b;color:#092012;font-weight:950;font-size:clamp(14px,1.4vw,45px);white-space:nowrap}#tickerMessage{flex:1;min-width:0;font-size:clamp(17px,1.8vw,58px);font-weight:750;white-space:nowrap;padding-left:100%;animation:combinedScroll 24s linear infinite}@keyframes combinedScroll{from{transform:translateX(0)}to{transform:translateX(-100%)}}
#lower{left:3%;top:51%;width:58%;height:17%;padding:1.1% 1.5%;border-left:clamp(5px,.5vw,18px) solid #b2d991;border-radius:clamp(5px,.5vw,14px);background:linear-gradient(100deg,#10281bf5,#0b120ef0);box-shadow:0 7px 24px #0008}
#lowerTitle{font-size:clamp(23px,2.6vw,86px);font-weight:950;line-height:1.08;overflow-wrap:anywhere}#lowerDetail{font-size:clamp(14px,1.5vw,48px);margin-top:.25em;color:#d6e8d3;overflow-wrap:anywhere}
#event{left:25%;top:22%;width:50%;height:42%;align-items:center;justify-content:center;flex-direction:column;padding:1.5%;text-align:center;border:clamp(2px,.2vw,6px) solid #fff;border-radius:clamp(9px,1vw,28px);background:linear-gradient(120deg,#15492bf5,#07160df5);box-shadow:0 8px 35px #0009}
#eventTitle{font-size:clamp(32px,4.1vw,132px);font-weight:1000;letter-spacing:.03em;line-height:1.04;overflow-wrap:anywhere}#eventDetail{font-size:clamp(14px,1.65vw,54px);font-weight:800;margin-top:.28em;overflow-wrap:anywhere}
#fullScreenScorecard{position:absolute;inset:0;z-index:2000;display:none;flex-direction:column;gap:1.1vh;padding:2.5vh 3vw;background:#0a1811;color:#f5faf5;overflow:hidden}
#fullScreenScorecard.transparent{background:transparent}
#fullScreenScorecard.style-tv{background:linear-gradient(135deg,#081c30f5,#102b43f2)}
#fullScreenScorecard.style-tv.transparent{background:transparent}
#fullScreenHeader{display:flex;align-items:flex-end;justify-content:space-between;gap:2vw;border-bottom:2px solid #a6d58a;padding-bottom:.65vh;min-height:7vh}
#fullScreenTitle{font-size:clamp(24px,2vw,48px);font-weight:950;letter-spacing:.02em;line-height:1.05}
#fullScreenMeta{font-size:clamp(13px,1vw,25px);font-weight:700;color:#c4d5c7;text-align:right}
#fullScreenContent{display:flex;flex-direction:column;gap:1.2vh;min-height:0;flex:1;overflow:hidden}
.fullScorecardPanel{display:flex;flex-direction:column;min-height:0;flex:1;overflow:hidden;border:1px solid #7c9982;border-radius:clamp(6px,.7vw,16px);background:#102118ed}
.fullScorecardPanel h2{font-size:clamp(15px,1.2vw,29px);font-weight:900;margin:0;padding:.55vh .8vw;background:#21442d;color:#f5fff3}
.fullScorecardSummary{font-size:clamp(12px,.95vw,24px);font-weight:750;padding:.35vh .8vw;color:#deebdd;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.fullScorecardTableWrap{min-height:0;flex:1;overflow:hidden}
.fullScorecardTable{border-collapse:collapse;width:100%;table-layout:fixed;font-size:clamp(13px,1vw,28px);line-height:1.12}
.fullScorecardTable th,.fullScorecardTable td{padding:.23vh .55vw;text-align:left;border-bottom:1px solid #ffffff20;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.fullScorecardTable th{font-size:.82em;letter-spacing:.04em;text-transform:uppercase;color:#e0eddf;background:#213c2a}
.fullScorecardTable th:not(:first-child),.fullScorecardTable td.num{text-align:right;font-variant-numeric:tabular-nums}
.fullScorecardTable tr:nth-child(even) td{background:#ffffff08}
#fullScreenScorecard.style-tv .fullScorecardPanel{border:0;border-radius:0;background:#0c2435dc;box-shadow:0 9px 28px #0006}
#fullScreenScorecard.style-tv .fullScorecardPanel h2{background:#d7b450;color:#132b3a}
#fullScreenScorecard.style-tv .fullScorecardTable th{background:#183d56}
#fullScreenScorecard.style-tv .fullScorecardTable tr:nth-child(even) td{background:#ffffff0d}
#fullScreenScorecard.transparent .fullScorecardPanel{background:#102118d9}
#fullScreenScorecard.style-tv.transparent .fullScorecardPanel{background:#0c2435df}
.fullXiGrid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:1.4vw;min-height:0;flex:1;overflow:hidden}
.fullXiPanel{min-height:0;overflow:hidden;border:1px solid #7c9982;background:#102118ed;border-radius:10px;display:flex;flex-direction:column}
.fullXiPanel h2{margin:0;background:#21442d;padding:.9vh 1vw;font-size:clamp(19px,1.5vw,34px)}
.fullXiList{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:.5vh 1vw;padding:1vh 1vw;font-size:clamp(15px,1.2vw,29px);font-weight:750;overflow:hidden}
.fullXiItem{padding:.35vh .3vw;border-bottom:1px solid #ffffff22;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#fullScreenScorecard.style-tv .fullXiPanel{border:0;background:#0c2435df}
#fullScreenScorecard.style-tv .fullXiPanel h2{background:#d7b450;color:#132b3a}
#eventMediaImage,#eventMediaVideo{display:none;position:absolute;inset:0;width:100%;height:100%;object-fit:contain;z-index:1}
#event.media-event{padding:0;border:0;border-radius:0;background:transparent;box-shadow:none;overflow:visible}
#event.media-event #eventDetail{position:absolute;z-index:2;bottom:2%;left:2%;right:2%;margin:0;padding:.35em .6em;border-radius:.35em;background:#07160dcc;text-align:center;overflow-wrap:anywhere}
@media (max-width:900px){.broadcast-bar{grid-template-columns:1.05fr .85fr 1.5fr .95fr 1fr}.section-label{letter-spacing:.04em}}
@media (prefers-reduced-motion:no-preference){#event.visible{animation:pop .2s ease-out}@keyframes pop{from{opacity:0;transform:scale(.94)}to{opacity:1;transform:scale(1)}}}
</style></head><body>
<div id="canvas" aria-label="Transparent combined cricket broadcast graphics">
<section id="scorecard" class="layer"><div class="broadcast-bar">
<div class="bar-section team-section"><div class="section-label">Batting</div><div class="team-heading"><div id="teamBadge" class="team-badge">TEAM</div><div id="teamName" class="team-name">Batting team</div></div><div id="teamMeta" class="team-meta">INNINGS 1</div></div>
<div class="bar-section score-section"><div class="section-label">Score</div><div id="scoreValue" class="score-value">0/0</div><div id="oversValue" class="overs-value">0.0 OV</div><div id="chaseValue" class="chase-value"></div></div>
<div class="bar-section batters-section"><div class="section-label">Batters · R (B)</div><div class="batter-row"><div id="batter1Name" class="batter-name">—</div><div id="batter1Stats" class="batter-stats"></div></div><div class="batter-row"><div id="batter2Name" class="batter-name">—</div><div id="batter2Stats" class="batter-stats"></div></div></div>
<div class="bar-section bowler-section"><div class="section-label">Bowler</div><div id="bowlerName" class="bowler-name">—</div><div id="bowlerFigures" class="bowler-figures">—</div><div id="bowlerEconomy" class="bowler-economy"></div></div>
<div class="bar-section recent-section"><div id="recentCaption" class="section-label">This over</div><div id="recentBalls" class="ball-list"><span class="empty-state">No balls yet</span></div></div>
</div></section>
<section id="ticker" class="layer"><div id="tickerLabel">LIVE</div><div id="tickerMessage"></div></section>
<section id="lower" class="layer"><div id="lowerTitle"></div><div id="lowerDetail"></div></section>
<section id="event" class="layer"><img id="eventMediaImage" alt=""><video id="eventMediaVideo" muted playsinline preload="auto"></video><div id="eventTitle"></div><div id="eventDetail"></div></section>
<section id="fullScreenScorecard"><header id="fullScreenHeader"><div id="fullScreenTitle"></div><div id="fullScreenMeta"></div></header><main id="fullScreenContent"></main></section>
</div>
<script>
const broadcastPageStartedAt=Date.now();
const setText=(id,value)=>{document.getElementById(id).textContent=value??'';};
const visible=(id,on)=>{const el=document.getElementById(id);el.style.display=on?((id==='ticker'||id==='event')?'flex':'block'):'none';};
function renderEventMedia(event,active){
 const root=document.getElementById('event');
 const image=document.getElementById('eventMediaImage');
 const video=document.getElementById('eventMediaVideo');
 const title=document.getElementById('eventTitle');
 const detail=document.getElementById('eventDetail');
 const mediaUrl=active&&typeof event.mediaUrl==='string'?event.mediaUrl:'';
 const mediaType=active?event.mediaType:null;
 const key=mediaUrl+'|'+(active?(event.createdAt||''):'');
 if(root.dataset.mediaKey!==key){
  root.dataset.mediaKey=key;
  video.pause();
  video.removeAttribute('src');
  image.removeAttribute('src');
  if(mediaUrl&&mediaType==='image'){
   image.src=mediaUrl;
   image.style.display='block';
   video.style.display='none';
  }else if(mediaUrl&&mediaType==='video'){
   video.src=mediaUrl;
   video.loop=event.loop===true;
   video.currentTime=0;
   video.style.display='block';
   image.style.display='none';
   video.load();
   video.play().catch(()=>{});
  }else{
   image.style.display='none';
   video.style.display='none';
  }
 }
 if(mediaUrl&&mediaType==='video')video.loop=event.loop===true;
 root.classList.toggle('media-event',Boolean(mediaUrl&&(mediaType==='image'||mediaType==='video')));
 title.style.display=mediaUrl?'none':'block';
 detail.style.display=active&&event.detail?'block':'none';
}

const defaultLayerSizes={scorecard:{width:94,height:8},ticker:{width:94,height:6.5},lowerThird:{width:58,height:17},lastBall:{width:50,height:42}};
const layoutElements={scorecard:'scorecard',ticker:'ticker',lowerThird:'lower',lastBall:'event'};
function applyLayout(layout,layerSettings){for(const key of Object.keys(layoutElements)){const rect=layout?.[key];const base=defaultLayerSizes[key];const el=document.getElementById(layoutElements[key]);const settings=layerSettings?.[key]||{};el.style.zIndex=String(Number.isFinite(Number(settings.zIndex))?Number(settings.zIndex):Object.keys(layoutElements).indexOf(key));if(!rect||!base)continue;const values=[rect.x,rect.y,rect.width,rect.height].map(Number);if(values.some(v=>!Number.isFinite(v)))continue;const [x,y,w,h]=values;if(x<0||y<0||w<=0||h<=0||x+w>100.01||y+h>100.01)continue;el.style.left=x+'%';el.style.top=y+'%';el.style.right='auto';el.style.bottom='auto';el.style.transformOrigin='top left';if(key==='scorecard'){el.style.width=w+'%';el.style.height=h+'%';el.style.transform='none';continue;}el.style.width=base.width+'%';el.style.height=base.height+'%';el.style.transform='scale('+(w/base.width)+','+(h/base.height)+')';}}
const abbrev=(name)=>{const words=(name||'TEAM').trim().split(/\s+/).filter(Boolean);return words.length>1?words.slice(0,3).map(word=>word[0]).join('').toUpperCase():(words[0]||'TEAM').slice(0,4).toUpperCase();};
const formatNumber=(value,digits=1)=>value==null?'—':Number(value).toFixed(digits);

let fullScreenLastSignature='';
function fullScreenElement(tag,className,text){const node=document.createElement(tag);if(className)node.className=className;if(text!=null)node.textContent=String(text);return node;}
function addFullScorecardPanel(host,title,summary,headers,rows){
 const panel=fullScreenElement('section','fullScorecardPanel');
 panel.appendChild(fullScreenElement('h2','',title));
 if(summary)panel.appendChild(fullScreenElement('div','fullScorecardSummary',summary));
 const wrap=fullScreenElement('div','fullScorecardTableWrap');
 const table=fullScreenElement('table','fullScorecardTable');
 const thead=fullScreenElement('thead');const headerRow=fullScreenElement('tr');
 for(const label of headers)headerRow.appendChild(fullScreenElement('th','',label));
 thead.appendChild(headerRow);table.appendChild(thead);
 const tbody=fullScreenElement('tbody');
 for(const values of rows){const tr=fullScreenElement('tr');for(let i=0;i<headers.length;i++){const td=fullScreenElement('td',i>=2?'num':'',values[i]??'—');tr.appendChild(td);}tbody.appendChild(tr);}
 table.appendChild(tbody);wrap.appendChild(table);panel.appendChild(wrap);
 if(!rows.length)panel.appendChild(fullScreenElement('div','fullScorecardSummary','No scorecard data available yet.'));
 host.appendChild(panel);return panel;
}
function battingRows(m){return(Array.isArray(m?.fullBattingScorecard)?m.fullBattingScorecard:[]).map(row=>[
 row.name||'Unknown Player',
 row.didNotBat?'Did not bat':(row.dismissal|| (row.isOut?'out':'not out')),
 row.runs??0,row.balls??0,row.fours??0,row.sixes??0,
 row.strikeRate==null?'—':Number(row.strikeRate).toFixed(1)
]);}
function bowlingRows(m){return(Array.isArray(m?.fullBowlingScorecard)?m.fullBowlingScorecard:[]).map(row=>[
 row.name||'Unknown Player',row.oversText||'0.0',
 row.maidens==null?'—':row.maidens,row.runsConceded??0,row.wickets??0,
 row.economyRate==null?'—':Number(row.economyRate).toFixed(2)
]);}
function renderFullScreenScorecard(state){
 const root=document.getElementById('fullScreenScorecard');
 const cfg=state.fullScreenScorecardSettings||{};
 const m=state.snapshot;
 const enabled=cfg.enabled===true&&Boolean(m&&m.ready);
 root.style.display=enabled?'flex':'none';
 root.classList.toggle('transparent',cfg.transparent===true);
 root.classList.toggle('style-tv',cfg.style==='tvBroadcast');
 const compact=document.getElementById('scorecard');
 const compactOn=enabled&&cfg.showCompactScorecard===true;
 visible('scorecard',Boolean(state.overlays?.scorecard&&m&&m.ready&&state.layerSettings?.scorecard?.visible!==false&&(!enabled||compactOn)));
 if(compactOn)compact.style.zIndex='2001';
 if(!enabled){root.dataset.renderKey='';return;}
 const view=['combined','batting','bowling','playingXi'].includes(cfg.view)?cfg.view:'combined';
 const signature=JSON.stringify([cfg,m]);
 if(root.dataset.renderKey===signature)return;
 root.dataset.renderKey=signature;
 const viewNames={combined:'Combined Batting & Bowling',batting:'Batting Scorecard',bowling:'Bowling Scorecard',playingXi:'Playing XI'};
 document.getElementById('fullScreenTitle').textContent=(m.matchName||'Cricket Match')+' · '+viewNames[view];
 document.getElementById('fullScreenMeta').textContent='INNINGS '+(m.inningsNumber||1)+' · '+(m.battingTeamName||'Batting')+' '+(m.runs??0)+'/'+(m.wickets??0)+' · '+(m.oversText||'0.0')+' OV';
 const host=document.getElementById('fullScreenContent');host.replaceChildren();
 if(view==='combined'||view==='batting'){
  const summary='TOTAL '+(m.runs??0)+'/'+(m.wickets??0)+' · '+(m.oversText||'0.0')+' OV · EXTRAS '+(m.extras??0)+' (Wd '+(m.wides??0)+', Nb '+(m.noBalls??0)+', B '+(m.byes??0)+', Lb '+(m.legByes??0)+')';
  addFullScorecardPanel(host,(m.battingTeamName||'Batting Team')+' · BATTING',summary,['BATTER','DISMISSAL','R','B','4s','6s','SR'],battingRows(m));
 }
 if(view==='combined'||view==='bowling'){
  addFullScorecardPanel(host,(m.bowlingTeamName||'Bowling Team')+' · BOWLING','Bowling figures for innings '+(m.inningsNumber||1),['BOWLER','O','M','R','W','ECON'],bowlingRows(m));
 }
 if(view==='playingXi'){
  const teams=Array.isArray(m.playingXiTeams)?m.playingXiTeams:[];
  const selected=cfg.playingXiMode==='single'?teams.slice(cfg.playingXiTeam==='teamB'?1:0,cfg.playingXiTeam==='teamB'?2:1):teams.slice(0,2);
  const grid=fullScreenElement('div','fullXiGrid');
  for(const team of selected){
   const panel=fullScreenElement('section','fullXiPanel');
   panel.appendChild(fullScreenElement('h2','',team.name||'Playing XI'));
   const list=fullScreenElement('div','fullXiList');
   const players=Array.isArray(team.players)?team.players.slice(0,11):[];
   players.forEach((name,index)=>{const item=fullScreenElement('div','fullXiItem',(index+1)+'. '+name);list.appendChild(item);});
   if(!players.length)list.appendChild(fullScreenElement('div','fullXiItem','No Playing XI selected.'));
   panel.appendChild(list);grid.appendChild(panel);
  }
  if(!selected.length)grid.appendChild(fullScreenElement('div','fullScorecardSummary','Playing XI is not available for this match.'));
  host.appendChild(grid);
 }
}
function renderBalls(balls){const host=document.getElementById('recentBalls');host.replaceChildren();if(!Array.isArray(balls)||balls.length===0){const empty=document.createElement('span');empty.className='empty-state';empty.textContent='No balls yet';host.appendChild(empty);return;}for(const delivery of balls){const item=document.createElement('span');item.className='ball';if(delivery.isWicket)item.classList.add('wicket');else if(delivery.totalRuns===4||delivery.totalRuns===6)item.classList.add('boundary');else if(!delivery.isLegalBall)item.classList.add('extra');item.textContent=delivery.label||'•';item.title=delivery.isWicket?'Wicket':(delivery.totalRuns+' run(s)');host.appendChild(item);}}
async function draw(){try{
const response=await fetch('/api/v1/broadcast/state',{cache:'no-store'});if(!response.ok)throw new Error('state unavailable');const state=await response.json();const m=state.snapshot;const ready=Boolean(m&&m.ready);const layerSettings=state.layerSettings||{};applyLayout(state.layout,layerSettings);const selectedStyle=state.scorecardStyle;document.getElementById('scorecard').dataset.style=['minimal','detailed','fullBroadcastBar'].includes(selectedStyle)?selectedStyle:'fullBroadcastBar';
visible('scorecard',Boolean(state.overlays?.scorecard&&ready&&layerSettings.scorecard?.visible!==false));
if(ready){
const battingTeam=m.battingTeamName||'Batting';setText('teamName',battingTeam);setText('teamBadge',abbrev(battingTeam));setText('teamMeta',(m.matchName||'MATCH')+' · INNINGS '+(m.inningsNumber||1));
setText('scoreValue',(m.runs??0)+'/'+(m.wickets??0));setText('oversValue',(m.oversText||'0.0')+' OV');
const chase=[];if(m.target!=null)chase.push('TARGET '+m.target);if(m.runsRequired!=null)chase.push(m.runsRequired+' NEEDED');if(m.requiredRunRate!=null)chase.push('RRR '+formatNumber(m.requiredRunRate));setText('chaseValue',chase.join(' · '));
const batters=Array.isArray(m.batters)?m.batters:[];for(let i=0;i<2;i++){const batter=batters[i];setText('batter'+(i+1)+'Name',batter?(batter.isOnStrike?'▶ ':'')+batter.name:'—');setText('batter'+(i+1)+'Stats',batter?batter.runs+' ('+batter.balls+') · 4s '+batter.fours+' · 6s '+batter.sixes:'');}
const bowler=m.bowler;if(bowler){setText('bowlerName',bowler.name);setText('bowlerFigures',bowler.oversText+' OV · '+bowler.runsConceded+' R · '+bowler.wickets+' W');setText('bowlerEconomy','ECON '+formatNumber(bowler.economyRate));}else{setText('bowlerName','—');setText('bowlerFigures','Waiting for bowler');setText('bowlerEconomy','');}
const deliveries=Array.isArray(m.currentOver)?m.currentOver:[];setText('recentCaption',deliveries.length?'THIS OVER':'RECENT BALLS');renderBalls(deliveries.length?deliveries:(m.recentDeliveries||[]));
}else{
for(const id of ['teamName','teamMeta','scoreValue','oversValue','chaseValue','batter1Name','batter1Stats','batter2Name','batter2Stats','bowlerName','bowlerFigures','bowlerEconomy'])setText(id,'');setText('teamBadge','TEAM');renderBalls([]);
}
const ticker=state.ticker;visible('ticker',Boolean(state.overlays?.ticker&&ticker&&layerSettings.ticker?.visible!==false));setText('tickerMessage',ticker?.title||'');
const lower=state.lowerThird;visible('lower',Boolean(state.overlays?.lowerThird&&lower&&layerSettings.lowerThird?.visible!==false));setText('lowerTitle',lower?.title||'');setText('lowerDetail',lower?.detail||'');
const event=state.event;const activeEvent=Boolean(state.overlays?.lastBall&&event&&layerSettings.lastBall?.visible!==false&&Date.parse(event.createdAt||'')>=broadcastPageStartedAt);visible('event',activeEvent);document.getElementById('event').classList.toggle('visible',activeEvent);setText('eventTitle',event?.title||'');setText('eventDetail',event?.detail||'');renderEventMedia(event||{},activeEvent);
renderFullScreenScorecard(state);
}catch(_){for(const id of ['scorecard','ticker','lower','event','fullScreenScorecard'])visible(id,false);}}
draw();setInterval(draw,250);
</script></body></html>''';

const String broadcastScorecardHtml = r'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cricket Scorecard</title>
<style>*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;background:transparent;overflow:hidden;font-family:Segoe UI,Arial,sans-serif;color:#fff}#wrap{display:none;width:max-content;max-width:96vw;background:linear-gradient(105deg,#0b2116f5,#174a2cf2);border:2px solid #b1d0a5;border-radius:18px;overflow:hidden;box-shadow:0 10px 30px #0008}.top{display:flex;align-items:center;gap:30px;padding:16px 24px}.teams{font-size:clamp(17px,2vw,34px);font-weight:800}.score{font-size:clamp(30px,3.4vw,58px);font-weight:900;white-space:nowrap}.meta{font-size:clamp(14px,1.2vw,22px);color:#d8e6d6;margin-top:3px}.bottom{display:flex;gap:24px;padding:10px 24px;background:#05130de8;font-size:clamp(13px,1.1vw,20px)}</style></head><body><div id="wrap"><div class="top"><div><div id="teams" class="teams"></div><div id="innings" class="meta"></div></div><div><div id="score" class="score"></div><div id="overs" class="meta"></div></div><div><div id="target" class="teams"></div><div id="required" class="meta"></div></div></div><div class="bottom"><div id="batters"></div><div id="bowler"></div></div></div>
<script>const txt=(id,v)=>document.getElementById(id).textContent=v??'';async function draw(){try{const r=await fetch('/api/v1/broadcast/state',{cache:'no-store'});const s=await r.json();const w=document.getElementById('wrap');const m=s.snapshot;w.style.display=s.overlays.scorecard&&m&&m.ready?'block':'none';if(!m||!m.ready)return;txt('teams',(m.battingTeamName||'Batting')+' v '+(m.bowlingTeamName||'Bowling'));txt('innings','INNINGS '+m.inningsNumber);txt('score',m.runs+'/'+m.wickets);txt('overs',m.oversText+' OVERS');txt('target',m.target==null?'':'TARGET '+m.target);txt('required',m.runsRequired==null?'':(m.runsRequired+' REQUIRED - '+(m.ballsRemaining??'-')+' BALLS'));txt('batters',(m.batters||[]).map(b=>(b.isOnStrike?'* ':'')+b.name+' '+b.runs+' ('+b.balls+')').join('  |  '));txt('bowler',m.bowler?m.bowler.name+'  '+m.bowler.oversText+'  '+m.bowler.wickets+'/'+m.bowler.runsConceded:'');}catch(_){document.getElementById('wrap').style.display='none';}}draw();setInterval(draw,500);</script></body></html>''';

const String broadcastTickerHtml = r'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cricket Ticker</title><style>*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;background:transparent;overflow:hidden;font-family:Segoe UI,Arial,sans-serif}#bar{display:none;position:absolute;bottom:3%;left:3%;right:3%;height:68px;background:#08140ff2;border-left:8px solid #a8d28b;border-radius:9px;overflow:hidden;color:#fff;align-items:center}#label{background:#a8d28b;color:#092012;font-weight:900;padding:0 20px;height:100%;display:flex;align-items:center;white-space:nowrap}#message{font-size:clamp(18px,1.8vw,30px);font-weight:750;white-space:nowrap;padding-left:100%;animation:scroll 24s linear infinite}@keyframes scroll{from{transform:translateX(0)}to{transform:translateX(-100%)}}</style></head><body><div id="bar"><div id="label">LIVE</div><div id="message"></div></div><script>async function draw(){try{const s=await(await fetch('/api/v1/broadcast/state',{cache:'no-store'})).json();const m=s.ticker;const b=document.getElementById('bar');b.style.display=s.overlays.ticker&&m?'flex':'none';document.getElementById('message').textContent=m?m.title:'';}catch(_){document.getElementById('bar').style.display='none';}}draw();setInterval(draw,500);</script></body></html>''';

const String broadcastLowerThirdHtml = r'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cricket Lower Third</title><style>*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;background:transparent;overflow:hidden;font-family:Segoe UI,Arial,sans-serif;color:#fff}#card{display:none;position:absolute;left:4%;bottom:9%;min-width:38%;max-width:78%;padding:18px 28px;background:linear-gradient(100deg,#10281bf5,#0b120ef0);border-left:9px solid #b2d991;border-radius:8px;box-shadow:0 7px 24px #0008}#title{font-size:clamp(26px,3vw,50px);font-weight:900}#detail{font-size:clamp(16px,1.7vw,29px);margin-top:5px;color:#d6e8d3}</style></head><body><div id="card"><div id="title"></div><div id="detail"></div></div><script>async function draw(){try{const s=await(await fetch('/api/v1/broadcast/state',{cache:'no-store'})).json();const m=s.lowerThird;const c=document.getElementById('card');c.style.display=s.overlays.lowerThird&&m?'block':'none';document.getElementById('title').textContent=m?m.title:'';document.getElementById('detail').textContent=m?m.detail||'':'';}catch(_){document.getElementById('card').style.display='none';}}draw();setInterval(draw,500);</script></body></html>''';

const String broadcastLastBallHtml = r'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cricket Event Graphic</title><style>*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;background:transparent;overflow:hidden;font-family:Segoe UI,Arial,sans-serif;color:#fff}#event{display:none;position:absolute;top:19%;left:50%;transform:translateX(-50%);min-width:42%;text-align:center;padding:24px 42px;border:3px solid #fff;border-radius:18px;background:linear-gradient(120deg,#15492bf5,#07160df5);box-shadow:0 8px 35px #0009;animation:pop .22s ease-out}#title{font-size:clamp(38px,6vw,100px);font-weight:1000;letter-spacing:.05em}#detail{font-size:clamp(18px,2.2vw,36px);font-weight:750}@keyframes pop{from{opacity:0;scale:.85}to{opacity:1;scale:1}}</style></head><body><div id="event"><div id="title"></div><div id="detail"></div></div><script>async function draw(){try{const s=await(await fetch('/api/v1/broadcast/state',{cache:'no-store'})).json();const m=s.event;const e=document.getElementById('event');e.style.display=s.overlays.lastBall&&m?'block':'none';document.getElementById('title').textContent=m?m.title:'';document.getElementById('detail').textContent=m?m.detail||'':'';}catch(_){document.getElementById('event').style.display='none';}}draw();setInterval(draw,250);</script></body></html>''';
