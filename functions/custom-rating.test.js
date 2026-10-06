const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createRatingHandler, validateConfig, validateMetadata, validateReview, checkSchemaChange, imageBytes} = require('./custom-rating');
const config = () => ({title: 'Kaffearkivet', itemTypeName: 'Kaffe', primaryLabel: 'Helhet', min: 0, max: 10, showSummary: true,
  criteria: [{id: 'aroma', label: 'Arom', min: 1, max: 5, showInRanking: true, highlightLabel: 'Bäst arom'}],
  metadataFields: [{id: 'country', label: 'Land', type: 'dropdown', options: ['Sverige', 'Italien'], required: false},
    {id: 'price', label: 'Pris', type: 'currency', currency: 'SEK'}, {id: 'again', label: 'Igen?', type: 'boolean'},
    {id: 'date', label: 'Datum', type: 'date'}]});
function fixture({member = true, role = 'member'} = {}) {
  const records = new Map();
  const snapshot = v => ({val: () => v ?? null, exists: () => v != null});
  const db = {ref(path) { return {
    get: async () => snapshot(path.startsWith('memberships/') ? (member ? {role} : null) : path.endsWith('/ownerId') ? 'owner' : records.get(path)),
    transaction: async update => {
      const next = update(structuredClone(records.get(path) ?? null));
      if (next !== undefined) records.set(path, next);
      return {committed: next !== undefined, snapshot: snapshot(next)};
    },
  }; }};
  return {records, handle: createRatingHandler({db, bucket: {file() { throw Error('Unexpected storage access'); }}})};
}
const req = (action, data = {}, uid = 'owner') => ({auth: {uid}, data: {groupId: 'group1', moduleId: 'main', action, ...data}});
const setup = f => f.handle(req('configure', {config: config(), revision: 0}));
const create = (f, id = 'one', uid = 'owner', extras = {}) => f.handle(req('saveItem', {id, version: 0, configRevision: 1, item: {title: 'Kaffe', metadataValues: {again: false, price: 0}}, review: {primaryRating: 0}, ...extras}, uid));
test('generic config validates field IDs, scale, options and limits', () => {
  assert.equal(validateConfig(config()).title, 'Kaffearkivet');
  for (const patch of [{min: 10}, {max: Infinity}, {title: ''}, {criteria: [null]}, {criteria: [{...config().criteria[0], id: '__proto__'}]}, {metadataFields: [{id: 'a', label: 'A', type: 'dropdown', options: []}]}, {criteria: [...config().criteria, ...config().criteria]}]) {
    assert.throws(() => validateConfig({...config(), ...patch}), {code: 'invalid-argument'});
  }
});
test('metadata preserves zero and false; validates required fields, options and real dates', () => {
  const c = validateConfig(config());
  assert.deepEqual(validateMetadata({price: 0, again: false, date: '2028-02-29'}, c), {price: 0, again: false, date: '2028-02-29'});
  for (const value of [{date: '2026-02-29'}, {country: 'Unknown'}, {again: 'false'}, {price: NaN}]) assert.throws(() => validateMetadata(value, c));
  c.metadataFields[0].required = true;
  assert.throws(() => validateMetadata({}, c));
});
test('missing ratings stay unknown and invalid criterion ranges are rejected', () => {
  const c = validateConfig(config());
  const review = validateReview({}, c, 'user', null, 10);
  assert.equal(review.primaryRating, null);
  assert.deepEqual(review.criterionRatings, {});
  assert.equal(validateReview({primaryRating: 0}, c, 'user', null, 10).primaryRating, 0);
  assert.throws(() => validateReview({criterionRatings: {aroma: 9}}, c, 'user', null, 10));
});
test('used schema permits labels and display changes but blocks destructive scale/type edits', () => {
  const c = validateConfig(config());
  assert.doesNotThrow(() => checkSchemaChange(c, {...c, title: 'Nytt namn'}, true));
  assert.throws(() => checkSchemaChange(c, {...c, max: 5}, true));
  assert.throws(() => checkSchemaChange(c, {...c, criteria: []}, true));
  assert.throws(() => checkSchemaChange(c, {...c, metadataFields: [{...c.metadataFields[0], required: true}]}, true));
});
test('all actions require authentication and membership; only admins configure', async () => {
  const f = fixture({member: false});
  await assert.rejects(f.handle({data: {}}), {code: 'unauthenticated'});
  for (const action of ['get', 'configure', 'saveItem', 'review', 'deleteItem']) await assert.rejects(f.handle(req(action, {}, 'outsider')), {code: 'permission-denied'});
  await assert.rejects(fixture().handle(req('configure', {revision: 0, config: config()}, 'member')), {code: 'permission-denied'});
  await assert.doesNotReject(fixture({role: 'admin'}).handle(req('configure', {revision: 0, config: config()}, 'adminUser')));
});
test('items enforce ownership, optimistic versions and separated member reviews', async () => {
  const f = fixture(); await setup(f); await create(f);
  await assert.rejects(create(f), {code: 'aborted'});
  await assert.rejects(f.handle(req('saveItem', {id: 'one', version: 1, configRevision: 1, item: {title: 'Overwrite'}}, 'member')), {code: 'permission-denied'});
  await f.handle(req('review', {id: 'one', configRevision: 1, reviewVersion: 0, review: {primaryRating: 8}}, 'member'));
  const module = (await f.handle(req('get'))).module;
  assert.equal(module.items.one.reviews.owner.primaryRating, 0);
  assert.equal(module.items.one.reviews.member.primaryRating, 8);
  assert.equal(module.items.one.version, 2);
  await assert.rejects(f.handle(req('review', {id: 'one', configRevision: 1, reviewVersion: 0, review: {primaryRating: 9}}, 'member')), {code: 'aborted'});
  await assert.rejects(f.handle(req('deleteItem', {id: 'one', configRevision: 1, version: 1})), {code: 'aborted'});
  await f.handle(req('deleteItem', {id: 'one', configRevision: 1, version: 2}));
  assert.deepEqual((await f.handle(req('get'))).module.items, {});
});
test('stale configuration cannot overwrite changes or save a stale item', async () => {
  const f = fixture(); await setup(f);
  await assert.rejects(setup(f), {code: 'aborted'});
  await f.handle(req('configure', {config: {...config(), title: 'New'}, revision: 1}));
  await assert.rejects(create(f), {code: 'aborted'});
});
test('demo import is explicit, atomic, cannot duplicate, and fabricates no criteria', async () => {
  const f = fixture();
  await f.handle(req('configure', {config: config(), revision: 0, seed: 'sardines'}));
  const items = Object.values((await f.handle(req('get'))).module.items);
  assert.equal(items.length, 14);
  assert.equal(items.find(i => i.title === 'Ortiz').reviews.imported.primaryRating, null);
  assert.equal(items.find(i => i.title === 'Ramón Peña Xeito').reviews.imported.primaryRating, 9.6);
  assert.ok(items.every(i => !i.reviews.imported.criterionRatings && i.reviews.imported.userId === null));
  await assert.rejects(f.handle(req('configure', {config: config(), revision: 1, seed: 'sardines'})));
});
test('image upload rejects disguised files and excessive payloads', () => {
  assert.throws(() => imageBytes('data:image/png;base64,' + Buffer.from('<svg/>').toString('base64')));
  assert.throws(() => imageBytes('a'.repeat(2800001)));
  assert.equal(imageBytes('data:image/png;base64,iVBORw0KGgo=').contentType, 'image/png');
});
test('item metadata edits preserve all reviews and reject forged creator/image fields', async () => {
  const f = fixture(); await setup(f); await create(f, 'one', 'member');
  await f.handle(req('review', {id: 'one', configRevision: 1, reviewVersion: 0, review: {primaryRating: 9}}, 'owner'));
  await f.handle(req('saveItem', {id: 'one', configRevision: 1, version: 2,
    item: {title: 'New title', creatorId: 'attacker', imageUrl: 'https://example.com/evil', createdAt: -1},
    review: {primaryRating: 1}}, 'member'));
  const saved = (await f.handle(req('get'))).module.items.one;
  assert.equal(saved.creatorId, 'member');
  assert.equal(saved.imageUrl, null);
  assert.equal(saved.reviews.owner.primaryRating, 9);
  assert.equal(saved.reviews.member.primaryRating, 0);
  assert.ok(saved.createdAt > 0);
  await assert.rejects(f.handle(req('deleteItem', {id: 'one', configRevision: 1, version: 3}, 'otherMember')), {code: 'permission-denied'});
});
test('image upload cleans up failed writes, replaced images, and rejects non-owners before storage access', async () => {
  const records = new Map([['customRatings/group1/main', {config: {...validateConfig(config()), revision: 1}, items: {one: {title: 'One', creatorId: 'owner', version: 1, imagePath: 'old-image'}}}]]);
  const files = [], removed = [];
  const snap = v => ({val: () => v, exists: () => v != null});
  const db = {ref: path => ({get: async () => snap(path.startsWith('memberships/') ? {role: 'member'} : path.endsWith('ownerId') ? 'owner' : records.get(path)),
    transaction: async fn => { const next = fn(structuredClone(records.get(path))); records.set(path, next); return {committed: true, snapshot: snap(next)}; }})};
  const bucket = {name: 'test', file: name => ({name, save: async () => files.push(name), delete: async () => removed.push(name)})};
  const handle = createRatingHandler({db, bucket});
  const input = {id: 'one', configRevision: 1, version: 1, item: {title: 'Changed'}, imageData: 'data:image/png;base64,iVBORw0KGgo='};
  await assert.rejects(handle(req('saveItem', input, 'member')), {code: 'permission-denied'});
  assert.equal(files.length, 0);
  await handle(req('saveItem', input));
  assert.ok(removed.includes('old-image'));
  await assert.rejects(handle(req('saveItem', input)), {code: 'aborted'});
  assert.ok(removed.includes(files.at(-1)));
});
