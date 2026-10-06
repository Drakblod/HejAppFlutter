// Explicit release smoke test. Creates two temporary accounts and one isolated
// group, then removes ONLY those resources. Never logs tokens or passwords.
const assert = require('node:assert/strict');
const {randomUUID, randomBytes} = require('node:crypto');
const {readFileSync} = require('node:fs');
const {Client} = require('../functions/node_modules/firebase-tools/lib/apiv2');
const {requireAuth} = require('../functions/node_modules/firebase-tools/lib/requireAuth');
const project = 'hejapp-a6614';
const origin = `https://${project}-default-rtdb.firebaseio.com`;
const groupId = `codex_smoke_${randomUUID().replaceAll('-', '')}`;
const accounts = [], uploads = [];
const configText = readFileSync(require('node:path').join(__dirname, '../lib/core/config/firebase_config.dart'), 'utf8');
const apiKey = configText.split('if (kIsWeb)')[1].match(/apiKey: '([^']+)'/)[1];
let adminDb, conversationId;
const options = {skipLog: {body: true, resBody: true}};
async function json(url, init = {}) {
  const response = await fetch(url, init);
  if (!(response.headers.get('content-type') || '').includes('json')) {
    const target = new URL(url);
    throw Error(`Non-JSON HTTP ${response.status} from ${target.hostname}${target.pathname}`);
  }
  const result = await response.json();
  if (!response.ok) throw Error(`HTTP ${response.status}: ${result.error?.status || result.error?.message || 'Request failed'}`);
  return result;
}
async function signup() {
  const result = await json(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`, {
    method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:`hej-smoke-${randomUUID()}@example.com`,password:randomBytes(32).toString('base64url'),returnSecureToken:true}),
  });
  const account = {uid:result.localId,token:result.idToken};
  accounts.push(account);
  return account;
}
async function db(account, path, method = 'GET', value) {
  return json(`${origin}/${path}.json?auth=${account.token}`, {method, headers:{'Content-Type':'application/json'}, ...(value === undefined ? {} : {body:JSON.stringify(value)})});
}
async function call(account, functionName, data) {
  const result = await json(`https://us-central1-${project}.cloudfunctions.net/${functionName}`, {method:'POST',headers:{'Content-Type':'application/json',Authorization:`Bearer ${account.token}`},body:JSON.stringify({data})});
  return result.result;
}
async function main() {
  if (!process.argv.includes('--run')) throw Error('Pass --run to explicitly run against production.');
  await requireAuth({project});
  adminDb = new Client({urlPrefix:origin,auth:true});
  const [owner, member] = [await signup(), await signup()];
  for (const account of accounts) await db(account, `profiles/${account.uid}`, 'PUT', {uid:account.uid,fullName:'Release smoke test',isAdmin:false});
  await db(owner, `groups/${groupId}`, 'PUT', {ownerId:owner.uid,name:'[Automatiskt test – tas bort]',enabledModules:{rating:true}});
  await db(owner, `memberships/${groupId}/${owner.uid}`, 'PUT', {role:'owner',joinedAt:Date.now()});
  await assert.rejects(call(member,'customRating',{action:'get',groupId}));
  await assert.rejects(db(member,`groups/${groupId}`));
  await db(member, '', 'PATCH', {[`memberships/${groupId}/${member.uid}`]:{role:'member',joinedAt:Date.now()},[`userGroups/${member.uid}/${groupId}`]:true});
  await call(owner,'customRating',{action:'configure',groupId,revision:0,config:{title:'Release smoke',itemTypeName:'Object',primaryLabel:'Score',min:0,max:10,criteria:[],metadataFields:[],showSummary:true}});
  await call(owner,'customRating',{action:'saveItem',groupId,id:'smoke',configRevision:1,version:0,item:{title:'Test object'},review:{primaryRating:8}});
  await call(member,'customRating',{action:'review',groupId,id:'smoke',configRevision:1,reviewVersion:0,review:{primaryRating:10}});
  const archive = await call(member,'customRating',{action:'get',groupId});
  assert.equal(archive.module.items.smoke.reviews[member.uid].primaryRating,10);
  await assert.rejects(db(owner,`customRatings/${groupId}`));
  await assert.rejects(db(member,`memberships/${groupId}/${member.uid}/role`,'PUT','admin'));
  console.log('PASS: authenticated rating create/review/read, membership isolation and direct-write denial');
  const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=';
  const uploaded = await call(owner,'workspaceAccess',{action:'upload',kind:'gallery',groupId,fileName:'smoke.png',base64:png});
  const url = new URL(uploaded.url);
  const parts = url.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
  uploads.push({bucket:parts[1],name:decodeURIComponent(parts[2])});
  assert.equal((await fetch(uploaded.url)).status,200);
  console.log('PASS: authorized upload and download-token image access');
  const conversation = await call(owner,'workspaceAccess',{action:'sendDirect',recipientId:member.uid,text:'Release smoke test'});
  conversationId = conversation.conversationId;
  const messages = await db(member,`directMessages/${conversationId}`);
  assert.equal(Object.values(messages)[0].senderId,owner.uid);
  console.log('PASS: private message delivery to the intended participant');
}
async function cleanup() {
  const errors = [];
  if (!groupId.startsWith('codex_smoke_')) throw Error('Invalid cleanup scope');
  if (adminDb && accounts.length) {
    const patch = {};
    for (const node of ['groups','memberships','customRatings']) patch[`${node}/${groupId}`] = null;
    for (const account of accounts) for (const node of ['profiles','userGroups','userDirectChats','workspaceUploadUsage']) patch[`${node}/${account.uid}`] = null;
    if (conversationId) {
      assert.equal(conversationId,accounts.map(a=>a.uid).sort().join('__'));
      patch[`directMessages/${conversationId}`] = null;
      patch[`directConversations/${conversationId}`] = null;
    }
    try { await adminDb.patch('/.json',patch,options); } catch { errors.push('temporary database records'); }
  }
  const storage = new Client({urlPrefix:'https://storage.googleapis.com',auth:true});
  for (const file of uploads) {
    assert.ok(file.name.startsWith(`gallery_photos/${groupId}/`));
    try { await storage.delete(`/storage/v1/b/${file.bucket}/o/${encodeURIComponent(file.name)}`,options); } catch { errors.push('temporary image'); }
  }
  for (const account of accounts) {
    try { await json(`https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${apiKey}`, {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({idToken:account.token})}); } catch { errors.push('temporary auth account'); }
  }
  if (errors.length) throw Error(`Cleanup incomplete (${groupId}): ${errors.join(', ')}`);
  console.log('Cleanup complete: temporary test accounts, group, messages and image removed.');
}
main().catch(error=>{console.error(error.message);process.exitCode=1;}).finally(async()=>{
  try { await cleanup(); } catch(error) {console.error(error.message);process.exitCode=1;}
});
