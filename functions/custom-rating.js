const {HttpsError} = require('firebase-functions/v2/https');
const {randomUUID} = require('crypto');
const {sardineItems} = require('./rating-presets');
const fail = (message, code = 'invalid-argument') => { throw new HttpsError(code, message); };
function text(value, max = 120, required = true) {
  if (typeof value !== 'string' || value.length > max || (required && !value.trim())) fail('Kontrollera textfälten.');
  return value.trim();
}
function key(value) {
  const result = text(value, 128);
  if (!/^[a-zA-Z0-9_-]+$/.test(result) || ['__proto__', 'constructor', 'prototype'].includes(result)) fail('Ogiltigt ID.');
  return result;
}
function number(value, min, max) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max) fail(`Ange ett tal mellan ${min} och ${max}.`);
  return value;
}
function scale(value) {
  const min = number(value.min, -10000, 10000), max = number(value.max, -10000, 10000);
  if (min >= max) fail('Skalans max måste vara större än min.');
  return {min, max};
}
function definitions(value, validate) {
  if (!Array.isArray(value) || value.length > 16) fail('Använd högst 16 fält av varje sort.');
  const result = value.map(v => {
    if (!v || typeof v !== 'object' || Array.isArray(v)) fail('Ogiltig fältdefinition.');
    return validate(v);
  });
  if (new Set(result.map(v => v.id)).size !== result.length) fail('Fältens ID måste vara unika.');
  return result;
}
function validateConfig(value) {
  if (!value || typeof value !== 'object') fail('Konfiguration saknas.');
  return {
    title: text(value.title, 80), itemTypeName: text(value.itemTypeName, 60),
    primaryLabel: text(value.primaryLabel, 60), ...scale(value),
    showSummary: value.showSummary === true,
    criteria: definitions(value.criteria ?? [], c => ({id: key(c.id), label: text(c.label, 60),
      ...scale(c), showInRanking: c.showInRanking === true, highlightLabel: text(c.highlightLabel ?? '', 60, false)})),
    metadataFields: definitions(value.metadataFields ?? [], f => {
      if (!['text', 'dropdown', 'number', 'currency', 'boolean', 'date'].includes(f.type)) fail('Okänd fälttyp.');
      const options = f.type === 'dropdown' ? (Array.isArray(f.options) ? f.options.map(v => text(v, 80)) : []) : [];
      if (f.type === 'dropdown' && (!options.length || options.length > 30 || new Set(options).size !== options.length)) fail('Ange 1–30 unika alternativ.');
      return {id: key(f.id), label: text(f.label, 60), type: f.type, required: f.required === true,
        options, currency: f.type === 'currency' ? text(f.currency, 8) : ''};
    }),
  };
}
function nullableRating(value, def) {
  return value === null || value === undefined ? null : number(value, def.min, def.max);
}
function validateReview(value, config, uid, previous, now) {
  const criterionRatings = {};
  for (const c of config.criteria ?? []) {
    const rating = nullableRating(value.criterionRatings?.[c.id], c);
    if (rating !== null) criterionRatings[c.id] = rating;
  }
  return {userId: uid, primaryRating: nullableRating(value.primaryRating, config), criterionRatings,
    comment: text(value.comment ?? '', 4000, false), createdAt: previous?.createdAt ?? now, updatedAt: Math.max(now, (previous?.updatedAt ?? 0) + 1)};
}
function validateMetadata(value, config) {
  const output = {};
  for (const f of config.metadataFields ?? []) {
    const v = value?.[f.id];
    if (v === null || v === undefined || v === '') {
      if (f.required) fail(`${f.label} måste fyllas i.`);
      continue;
    }
    if (f.type === 'boolean') {
      if (typeof v !== 'boolean') fail(`${f.label}: välj ja eller nej.`);
    } else if (f.type === 'number' || f.type === 'currency') number(v, -1e9, 1e9);
    else {
      text(v, f.type === 'text' ? 1000 : 80);
      if (f.type === 'dropdown' && !f.options.includes(v)) fail(`${f.label}: välj ett giltigt alternativ.`);
      if (f.type === 'date') {
        const date = new Date(`${v}T12:00:00Z`);
        if (!/^\d{4}-\d{2}-\d{2}$/.test(v) || !Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== v) fail(`${f.label}: ange ett giltigt datum.`);
      }
    }
    output[f.id] = v;
  }
  return output;
}
function checkSchemaChange(old, next, hasItems) {
  if (!hasItems) return;
  if (old.min !== next.min || old.max !== next.max) fail('Betygsskalan är låst när arkivet innehåller objekt.');
  for (const c of old.criteria ?? []) {
    const n = next.criteria.find(v => v.id === c.id);
    if (!n || c.min !== n.min || c.max !== n.max) fail('Befintliga kriterier och skalor kan inte tas bort eller ändras när objekt finns.');
  }
  for (const f of old.metadataFields ?? []) {
    const n = next.metadataFields.find(v => v.id === f.id);
    if (!n || f.type !== n.type || f.currency !== n.currency || (f.options ?? []).some(v => !n.options.includes(v))) fail('Befintliga fälttyper, valutor och alternativ måste bevaras.');
  }
  for (const f of next.metadataFields) {
    if (f.required && !(old.metadataFields ?? []).find(v => v.id === f.id)?.required) fail('Nya obligatoriska fält kräver först en datamigrering.');
  }
}
function imageBytes(value) {
  if (typeof value !== 'string' || value.length > 2800000) fail('Bilden får vara högst 2 MB.');
  const match = /^data:image\/(jpeg|png|webp);base64,([A-Za-z0-9+/=]+)$/.exec(value);
  if (!match) fail('Välj JPG, PNG eller WebP.');
  const bytes = Buffer.from(match[2], 'base64');
  const valid = match[1] === 'png' ? bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))
    : match[1] === 'jpeg' ? bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255
      : bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP';
  if (!valid || bytes.length > 2 * 1024 * 1024) fail('Ogiltig bild eller för stor fil.');
  return {bytes, contentType: `image/${match[1]}`};
}
function createRatingHandler({db, bucket}) {
  return async request => {
    if (!request.auth) fail('Logga in först.', 'unauthenticated');
    const uid = request.auth.uid, data = request.data ?? {};
    const groupId = key(data.groupId), moduleId = key(data.moduleId ?? 'main');
    const [member, owner] = await Promise.all([db.ref(`memberships/${groupId}/${uid}`).get(), db.ref(`groups/${groupId}/ownerId`).get()]);
    const isAdmin = owner.val() === uid || member.val()?.role === 'admin';
    if (!member.exists() && owner.val() !== uid) fail('Du måste vara medlem i gruppen.', 'permission-denied');
    const target = db.ref(`customRatings/${groupId}/${moduleId}`);
    if (data.action === 'get') return {module: (await target.get()).val(), canConfigure: isAdmin, userId: uid};
    if (!['configure', 'saveItem', 'review', 'deleteItem'].includes(data.action)) fail('Okänd åtgärd.');
    if (data.action === 'configure' && !isAdmin) fail('Endast gruppadministratörer kan konfigurera modulen.', 'permission-denied');
    const id = data.action === 'configure' ? null : key(data.id);
    let uploaded, newImage;
    // Upload through the authenticated backend; clients never choose storage paths.
    if (data.imageData && data.action === 'saveItem') {
      const current = (await target.get()).val();
      const item = current?.items?.[id];
      if (!current?.config) fail('Konfigurera modulen först.', 'failed-precondition');
      if (item && item.creatorId !== uid && !isAdmin) fail('Du kan bara redigera egna objekt.', 'permission-denied');
      const {bytes, contentType} = imageBytes(data.imageData);
      const token = randomUUID();
      uploaded = bucket.file(`rating_images/${groupId}/${moduleId}/${id}/${randomUUID()}`);
      await uploaded.save(bytes, {resumable: false, metadata: {contentType, metadata: {firebaseStorageDownloadTokens: token}}});
      newImage = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(uploaded.name)}?alt=media&token=${token}`;
    }
    let oldImagePath;
    try {
      const now = Date.now();
      const result = await target.transaction(current => {
        // RTDB may initially invoke a transaction with an empty local cache.
        // A null no-op lets the server supply its current value for a retry.
        if (!current && (data.action !== 'configure' || data.revision > 0)) return null;
        if (data.action === 'configure') {
          if ((current?.config?.revision ?? 0) !== data.revision) fail('Inställningarna har ändrats. Stäng och öppna formuläret igen.', 'aborted');
          const config = validateConfig(data.config);
          checkSchemaChange(current?.config, config, Object.keys(current?.items ?? {}).length > 0);
          const next = {...(current ?? {}), config: {...config, id: moduleId, groupId, revision: data.revision + 1, updatedAt: now}};
          if (data.seed) {
            if (data.seed !== 'sardines' || current?.config || config.min !== 0 || config.max !== 10 || config.metadataFields.some(f => f.required)) fail('Demodata kan endast läggas till i ett nytt arkiv med skala 0–10 och valfria metadatafält.');
            next.items = Object.fromEntries(sardineItems.map(([title, rating, comment = ''], i) => [`demo_${i}`, {
              id: `demo_${i}`, moduleId, title, creatorId: uid, createdAt: now, updatedAt: now, version: 1,
              // Imported historical scores are not attributed to the importing user.
              reviews: {imported: {userId: null, sourceLabel: 'Importerad demodata', primaryRating: rating, comment, createdAt: now, updatedAt: now}},
            }]));
          }
          return next;
        }
        if (!current?.config) fail('Konfigurera modulen först.', 'failed-precondition');
        if (current.config.revision !== data.configRevision) fail('Modulens inställningar har ändrats. Uppdatera och försök igen.', 'aborted');
        const items = {...(current.items ?? {})}, old = items[id];
        if (data.action === 'review') {
          if (!old) fail('Objektet finns inte kvar.', 'not-found');
          if ((old.reviews?.[uid]?.updatedAt ?? 0) !== data.reviewVersion) fail('Din recension har ändrats. Öppna formuläret igen.', 'aborted');
          items[id] = {...old, reviews: {...(old.reviews ?? {}), [uid]: validateReview(data.review ?? {}, current.config, uid, old.reviews?.[uid], now)}, updatedAt: now, version: old.version + 1};
        } else {
          if (old && old.creatorId !== uid && !isAdmin) fail('Du kan bara ändra egna objekt.', 'permission-denied');
          if ((old?.version ?? 0) !== data.version) fail('Objektet har ändrats. Öppna det igen.', 'aborted');
          if (data.action === 'deleteItem') {
            if (!old) fail('Objektet finns inte kvar.', 'not-found');
            oldImagePath = old.imagePath;
            delete items[id];
          } else {
            if (!old && Object.keys(items).length >= 300) fail('Testversionen stöder högst 300 objekt per arkiv.', 'resource-exhausted');
            const value = data.item ?? {};
            oldImagePath = (newImage || data.removeImage) ? old?.imagePath : null;
            items[id] = {...(old ?? {}), id, moduleId, title: text(value.title, 160),
              metadataValues: validateMetadata(value.metadataValues, current.config),
              imageUrl: newImage ?? (data.removeImage ? null : old?.imageUrl ?? null),
              imagePath: uploaded?.name ?? (data.removeImage ? null : old?.imagePath ?? null),
              creatorId: old?.creatorId ?? uid, createdAt: old?.createdAt ?? now, updatedAt: now, version: (old?.version ?? 0) + 1};
            if (!old) items[id].reviews = {[uid]: validateReview(data.review ?? {}, current.config, uid, null, now)};
          }
        }
        return {...current, items};
      });
      if (!result.committed) fail('Kunde inte spara. Försök igen.', 'aborted');
      if (!result.snapshot.val()?.config) fail('Konfigurera modulen först.', 'failed-precondition');
    } catch (error) {
      if (uploaded) await uploaded.delete({ignoreNotFound: true}).catch(() => {});
      throw error;
    }
    if (oldImagePath) await bucket.file(oldImagePath).delete({ignoreNotFound: true}).catch(() => {});
    return {ok: true};
  };
}
module.exports = {createRatingHandler, validateConfig, validateReview, validateMetadata, checkSchemaChange, imageBytes};
