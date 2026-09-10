const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createCalendarHandler, validateEvent, validDate} = require('./calendar-box');

const event = {title: 'Konsert', date: '2026-10-24', time: '18:30', sourceUrl: 'https://example.com/event'};
function fixture({member = true, failAI = false} = {}) {
  const records = new Map();
  let aiCalls = 0;
  const snapshot = value => ({val: () => value, exists: () => value != null});
  const db = {ref(path) {
    return {
      child: id => db.ref(`${path}/${id}`),
      get: async () => snapshot(path.startsWith('memberships/') ? member ? {role: 'member'} : null : records.get(path) ?? null),
      transaction: async update => {
        const value = update(records.get(path) ?? null);
        if (value !== undefined) records.set(path, value);
        return {committed: value !== undefined, snapshot: snapshot(records.get(path))};
      },
    };
  }};
  const ai = () => ({responses: {create: async options => {
    aiCalls++;
    assert.equal(options.store, false);
    assert.equal(options.text.format.strict, true);
    if (failAI) throw {status: 401};
    return {status: 'completed', output_text: JSON.stringify({...event, date: null, warnings: ['År saknas.']})};
  }}});
  return {records, calls: () => aiCalls, handle: createCalendarHandler({db, ai})};
}
const req = data => ({auth: {uid: 'u1'}, data: {groupId: 'g1', ...data}});
test('validates real dates, leap years, local time and safe source links', () => {
  assert.equal(validDate('2028-02-29'), true);
  assert.equal(validDate('2026-02-29'), false);
  assert.equal(validDate('2026-04-31'), false);
  assert.equal(validateEvent(event).time, '18:30');
  assert.equal(validateEvent({...event, time: ''}).time, '');
  for (const bad of [{date: '2026-02-30'}, {time: '24:00'}, {title: ''}, {sourceUrl: 'javascript:alert(1)'}]) {
    assert.throws(() => validateEvent({...event, ...bad}));
  }
});
test('requires authentication and group membership before any AI or writes', async () => {
  const f = fixture({member: false});
  await assert.rejects(f.handle({data: {}}), {code: 'unauthenticated'});
  await assert.rejects(f.handle(req({action: 'extract', text: 'Konsert'})), {code: 'permission-denied'});
  assert.equal(f.calls(), 0);
  assert.equal(f.records.size, 0);
});
test('AI extraction creates a draft only and missing date stays unknown', async () => {
  const f = fixture();
  const result = await f.handle(req({action: 'extract', text: 'Konsert 24 oktober'}));
  assert.equal(result.draft.date, null);
  assert.equal([...f.records.keys()].some(k => k.startsWith('calendarBox/')), false);
});
test('save requires confirmation and retry produces one event', async () => {
  const f = fixture();
  await assert.rejects(f.handle(req({action: 'save', id: 'draft1', event})), {code: 'failed-precondition'});
  await f.handle(req({action: 'save', id: 'draft1', confirmed: true, event}));
  await f.handle(req({action: 'save', id: 'draft1', confirmed: true, event}));
  assert.equal(f.records.size, 1);
  assert.equal(f.records.get('calendarBox/g1/draft1').creatorId, 'u1');
});
test('URL-only input rejected without calling AI and errors allow manual fallback', async () => {
  const f = fixture({failAI: true});
  await assert.rejects(f.handle(req({action: 'extract', text: 'https://example.com/'})), {code: 'invalid-argument'});
  assert.equal(f.calls(), 0);
  await assert.rejects(f.handle(req({action: 'extract', text: 'Konsert'})), {code: 'unavailable'});
  await f.handle(req({action: 'save', confirmed: true, id: 'manual', event}));
  assert.ok(f.records.has('calendarBox/g1/manual'));
});
test('daily AI quota is enforced without affecting manual saves', async () => {
  const f = fixture();
  for (let i = 0; i < 20; i++) await f.handle(req({action: 'extract', text: 'Konsert'}));
  await assert.rejects(f.handle(req({action: 'extract', text: 'Konsert'})), {code: 'resource-exhausted'});
  assert.equal(f.calls(), 20);
  await f.handle(req({action: 'save', confirmed: true, id: 'manual', event}));
});
