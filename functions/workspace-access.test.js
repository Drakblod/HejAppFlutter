const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createWorkspaceHandler} = require('./workspace-access');
function fixture(member = true) {
  const writes = [], uploads = [];
  const db = {ref(path = '') { return {
    get: async () => ({exists: () => path.startsWith('memberships') && member,
      val: () => path.endsWith('ownerId') ? 'owner' : path.startsWith('profiles/') ? {fullName:'Actual sender'} : null}),
    push: () => ({key:'message1'}), update: async value => writes.push(value),
    transaction: async fn => ({committed: fn(0) !== undefined}),
  }; }};
  const bucket = {name:'test', file: name => ({name, save: async (bytes, options) => uploads.push({name, bytes, options})})};
  return {writes, uploads, handle: createWorkspaceHandler({db,bucket,auth:{getUser: async uid => { if (uid === 'missing') throw Error('not found'); return {uid}; }}})};
}
const req = (data, uid = 'member') => ({auth:{uid},data});
test('workspace rejects anonymous users and invalid actions', async () => {
  const f = fixture();
  await assert.rejects(f.handle({data:{}}), {code:'unauthenticated'});
  await assert.rejects(f.handle(req({action:'unknown'})), {code:'invalid-argument'});
});
test('DM participants and sender identity always come from authenticated caller', async () => {
  const f = fixture();
  await f.handle(req({action:'sendDirect', recipientId:'owner', senderId:'spoof', senderName:'Fake', text:'Hi'}));
  const writes = f.writes[0];
  assert.equal(writes['directMessages/member__owner/message1'].senderId, 'member');
  assert.equal(writes['directMessages/member__owner/message1'].senderName, 'Actual sender');
  assert.equal(writes['userDirectChats/owner/member__owner'], true);
  await assert.rejects(f.handle(req({action:'sendDirect',recipientId:'owner',text:''})), {code:'invalid-argument'});
  await assert.rejects(f.handle(req({action:'startDirect',recipientId:'missing'})), {code:'not-found'});
});
test('upload checks group membership and owner-only background permission', async () => {
  const input = {action:'upload',kind:'gallery',groupId:'g',fileName:'photo.png',base64:'aGVsbG8='};
  await assert.rejects(fixture(false).handle(req(input)), {code:'permission-denied'});
  const f = fixture();
  await f.handle(req(input));
  assert.ok(f.uploads[0].name.startsWith('gallery_photos/g/'));
  await assert.rejects(f.handle(req({...input,kind:'background'})), {code:'permission-denied'});
  await f.handle(req({...input,kind:'background'}, 'owner'));
});
test('profile uploads cannot choose another user path and shared files are attachments', async () => {
  const f = fixture(false);
  await f.handle(req({action:'upload',kind:'profile',uid:'other',fileName:'image.jpg',base64:'aGVsbG8='}));
  assert.ok(f.uploads[0].name.startsWith('profile_photos/member/'));
  const member = fixture();
  await member.handle(req({action:'upload',kind:'file',groupId:'g',fileName:'test.html',base64:'aGVsbG8='}));
  assert.equal(member.uploads[0].options.metadata.contentType,'application/octet-stream');
  assert.ok(member.uploads[0].options.metadata.contentDisposition.startsWith('attachment;'));
});
