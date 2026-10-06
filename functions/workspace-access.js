const {HttpsError} = require('firebase-functions/v2/https');
const {randomUUID} = require('crypto');
const fail = (code, message) => { throw new HttpsError(code, message); };
function key(v) {
  if (typeof v !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(v)) fail('invalid-argument', 'Ogiltigt ID.');
  return v;
}
function createWorkspaceHandler({db, bucket, auth}) {
  return async request => {
    if (!request.auth) fail('unauthenticated', 'Logga in först.');
    const uid = request.auth.uid, data = request.data ?? {};
    if (data.action === 'startDirect' || data.action === 'sendDirect') {
      const other = key(data.recipientId);
      if (other === uid) fail('invalid-argument', 'Välj en annan medlem.');
      try { await auth.getUser(other); } catch { fail('not-found', 'Användaren finns inte.'); }
      const id = [uid, other].sort().join('__');
      const existing = (await db.ref(`directConversations/${id}/participants`).get()).val();
      if (existing && (!existing[uid] || !existing[other] || Object.keys(existing).length !== 2)) fail('permission-denied', 'Ogiltig konversation.');
      const updates = {
        [`directConversations/${id}/participants/${uid}`]: true,
        [`directConversations/${id}/participants/${other}`]: true,
        [`directConversations/${id}/updatedAt`]: Date.now(),
        [`userDirectChats/${uid}/${id}`]: true,
        [`userDirectChats/${other}/${id}`]: true,
      };
      if (data.action === 'sendDirect') {
        if (typeof data.text !== 'string' || !data.text.trim() || data.text.length > 10000) fail('invalid-argument', 'Skriv ett meddelande på högst 10 000 tecken.');
        const profile = (await db.ref(`profiles/${uid}`).get()).val() ?? (await db.ref(`users/${uid}`).get()).val() ?? {};
        const messageId = db.ref(`directMessages/${id}`).push().key;
        updates[`directMessages/${id}/${messageId}`] = {groupId: id, senderId: uid, senderName: profile.fullName || profile.username || 'Gruppmedlem', senderPhotoUrl: profile.photoUrl || null, text: data.text.trim(), ts: Date.now()};
        updates[`directConversations/${id}/lastMessage`] = data.text.trim();
        updates[`directConversations/${id}/lastSenderId`] = uid;
      }
      await db.ref().update(updates);
      return {conversationId: id};
    }
    if (data.action !== 'upload') fail('invalid-argument', 'Okänd åtgärd.');
    const folders = {chat: 'chat_photos', profile: 'profile_photos', background: 'group_backgrounds', file: 'shared_files', gallery: 'gallery_photos'};
    if (!Object.hasOwn(folders, data.kind)) fail('invalid-argument', 'Okänd filtyp.');
    let scope = uid;
    if (data.kind !== 'profile') {
      scope = key(data.groupId);
      const [owner, membership] = await Promise.all([db.ref(`groups/${scope}/ownerId`).get(), db.ref(`memberships/${scope}/${uid}`).get()]);
      if (owner.val() !== uid && (!membership.exists() || data.kind === 'background')) fail('permission-denied', 'Du saknar behörighet för uppladdningen.');
    }
    if (typeof data.base64 !== 'string' || data.base64.length > 8400000 || !/^[A-Za-z0-9+/=]+$/.test(data.base64)) fail('invalid-argument', 'Filen får vara högst 6 MB.');
    const bytes = Buffer.from(data.base64, 'base64');
    if (!bytes.length || bytes.length > 6 * 1024 * 1024) fail('invalid-argument', 'Filen får vara högst 6 MB.');
    const fileName = typeof data.fileName === 'string' ? data.fileName.replace(/[^\p{L}\p{N}._ -]/gu, '_').slice(0, 150) : 'file';
    const ext = fileName.split('.').pop().toLowerCase();
    const types = {jpg:'image/jpeg', jpeg:'image/jpeg', png:'image/png', webp:'image/webp', gif:'image/gif', heic:'image/heic'};
    if (data.kind !== 'file' && !types[ext]) fail('invalid-argument', 'Välj en bildfil.');
    const day = new Date().toISOString().slice(0, 10);
    const quota = await db.ref(`workspaceUploadUsage/${uid}/${day}`).transaction(n => (n ?? 0) < 100 ? (n ?? 0) + 1 : undefined);
    if (!quota.committed) fail('resource-exhausted', 'Dagens gräns på 100 uppladdningar är nådd.');
    const file = bucket.file(`${folders[data.kind]}/${scope}/${randomUUID()}_${fileName}`), token = randomUUID();
    await file.save(bytes, {resumable: false, metadata: {
      contentType: data.kind === 'file' ? 'application/octet-stream' : types[ext],
      ...(data.kind === 'file' ? {contentDisposition: `attachment; filename*=UTF-8''${encodeURIComponent(fileName)}`} : {}),
      metadata: {firebaseStorageDownloadTokens: token, uploaderId: uid},
    }});
    return {url: `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`};
  };
}
module.exports = {createWorkspaceHandler};
