const {test, before, after, beforeEach} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {ref, set, get, update} = require('firebase/database');
const {ref: storageRef, uploadBytes, getMetadata} = require('firebase/storage');
const admin = require('../functions/node_modules/firebase-admin');
const {createRatingHandler} = require('../functions/custom-rating');
let env;
const db = uid => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).database();
before(async () => {
  admin.initializeApp({projectId: 'demo-hej-security', databaseURL: 'https://demo-hej-security.firebaseio.com'});
  env = await initializeTestEnvironment({projectId: 'demo-hej-security',
    database: {host: '127.0.0.1', port: 9000, rules: readFileSync('../database.rules.json', 'utf8')},
    storage: {host: '127.0.0.1', port: 9199, rules: readFileSync('../storage.rules', 'utf8')},
  });
});
after(async () => { if (env) await env.cleanup(); await admin.app().delete(); });
beforeEach(async () => {
  await env.withSecurityRulesDisabled(async context => set(ref(context.database()), {
    groups: {g: {ownerId: 'owner', name: 'Group'}, other: {ownerId: 'outside', name: 'Private'}},
    memberships: {g: {owner: {role: 'owner', joinedAt: 1}, member: {role: 'member', joinedAt: 1}}, other: {outside: {role: 'owner', joinedAt: 1}}},
    userGroups: {member: {g: true}}, profiles: {owner: {isAdmin: true}, member: {isAdmin: false}},
    directConversations: {member__owner: {participants: {member: true, owner: true}}},
    directMessages: {member__owner: {m: {senderId: 'owner', text: 'Private'}}},
    customRatings: {g: {main: {config: {title: 'Archive'}}}},
  }));
});
test('anonymous and cross-group access denied; owner/member can read group', async () => {
  for (const uid of [null, 'outside']) {
    for (const node of ['groups/g','memberships/g','messages/g','postits/g','files/g','gallery/g','groupTasks/g','groupPolls/g','groupProposals/g']) await assertFails(get(ref(db(uid), node)));
  }
  await assertSucceeds(get(ref(db('member'), 'groups/g')));
  await assertFails(get(ref(db('member'), 'groups')));
  await assertSucceeds(get(ref(db('outside'), 'groups/g/name')));
});
test('owner creates group; invite-code join is atomic; members cannot elevate role or ownership', async () => {
  const user = db('new');
  await assertSucceeds(set(ref(user, 'groups/new'), {name: 'New', ownerId: 'new'}));
  await assertSucceeds(set(ref(user, 'memberships/new/new'), {role: 'owner', joinedAt: 1}));
  await assertSucceeds(set(ref(user, 'userGroups/new/new'), true));
  await assertSucceeds(update(ref(user), {'memberships/g/new': {role: 'member', joinedAt: 1}, 'userGroups/new/g': true}));
  await assertFails(set(ref(user, 'memberships/g/new/role'), 'admin'));
  await assertFails(set(ref(user, 'groups/g/ownerId'), 'new'));
  await assertFails(set(ref(user, 'memberships/other/new'), {role: 'owner', joinedAt: 1}));
  await assertSucceeds(set(ref(user, 'memberships/g/new/lastReadTs'), 123));
  await assertSucceeds(update(ref(user), {'memberships/g/new': null, 'userGroups/new/g': null}));
});
test('owner can remove members and delete a group with existing client atomic update', async () => {
  await assertSucceeds(update(ref(db('owner')), {'memberships/g/member': null, 'userGroups/member/g': null}));
  await assertSucceeds(update(ref(db('owner')), {'groups/g': null, 'memberships/g': null, 'messages/g': null, 'postits/g': null}));
});
test('self profile edits cannot grant or remove admin privileges, usernames cannot be stolen', async () => {
  const member = db('member');
  await assertSucceeds(update(ref(member, 'profiles/member'), {fullName: 'Updated'}));
  await assertFails(set(ref(member, 'profiles/member/isAdmin'), true));
  await assertFails(set(ref(member, 'users/member/isAdmin'), true));
  await assertFails(set(ref(member, 'profiles/owner'), {isAdmin: false}));
  await assertFails(set(ref(db('owner'), 'profiles/owner'), {fullName: 'Drops privilege'}));
  await assertSucceeds(set(ref(member, 'usernames/membername'), 'member'));
  await assertFails(set(ref(db('outside'), 'usernames/membername'), 'outside'));
  await assertFails(get(ref(member, 'deviceTokens/owner')));
});
test('group content author checks and collaborative tasks work', async () => {
  for (const [node, author] of [['messages','senderId'],['postits','senderId'],['files','senderId'],['gallery','uploaderId']]) {
    await assertSucceeds(set(ref(db('member'), `${node}/g/item`), {[author]: 'member', text: 'Hello'}));
    await assertFails(set(ref(db('member'), `${node}/g/spoof`), {[author]: 'owner'}));
    await assertFails(set(ref(db('outside'), `${node}/g/item`), null));
  }
  await assertSucceeds(set(ref(db('owner'), 'groupTasks/g/t'), {creatorId: 'owner', title: 'Task', isDone: false}));
  await assertSucceeds(set(ref(db('member'), 'groupTasks/g/t/isDone'), true));
  await assertFails(set(ref(db('member'), 'groupTasks/g/t/title'), 'Hijack'));
  await assertSucceeds(set(ref(db('member'), 'groupProposals/g/p'), {creatorId:'member', votes:{0:['member']}}));
});
test('poll votes are own-user only and closed polls reject votes', async () => {
  await assertSucceeds(set(ref(db('owner'), 'groupPolls/g/p'), {question:'Pick', creatorId:'owner', options:['A','B'], closesAt: Date.now()+600000, isClosed:false}));
  await assertSucceeds(set(ref(db('member'), 'groupPolls/g/p/votes/member'), '0'));
  await assertFails(set(ref(db('member'), 'groupPolls/g/p/votes/owner'), '0'));
  await assertFails(set(ref(db('member'), 'groupPolls/g/p/votes/member'), '99'));
  await assertSucceeds(set(ref(db('owner'), 'groupPolls/g/p/isClosed'), true));
  await assertFails(set(ref(db('member'), 'groupPolls/g/p/votes/member'), '1'));
});
test('private messages are participant-read and server-write only', async () => {
  await assertSucceeds(get(ref(db('member'), 'directMessages/member__owner')));
  await assertFails(get(ref(db('outside'), 'directMessages/member__owner')));
  await assertFails(set(ref(db('member'), 'directConversations/member__owner/participants/outside'), true));
  await assertFails(set(ref(db('member'), 'userDirectChats/outside/member__owner'), true));
  await assertFails(set(ref(db('member'), 'directMessages/member__owner/m'), {text:'Forged'}));
});
test('rating/calendar/counters deny even owner direct reads and writes', async () => {
  for (const node of ['customRatings','calendarBox','calendarBoxUsage','workspaceUploadUsage']) {
    await assertFails(get(ref(db('owner'), `${node}/g`)));
    await assertFails(set(ref(db('owner'), `${node}/g`), {hacked:true}));
  }
  await assertFails(update(ref(db('owner')), {'customRatings/g': null}));
});
test('storage blocks unauthenticated and authenticated direct mutation', async () => {
  for (const context of [env.unauthenticatedContext(), env.authenticatedContext('owner')]) {
    for (const folder of ['rating_images','chat_photos','profile_photos','group_backgrounds','shared_files','gallery_photos']) {
      const target = storageRef(context.storage(), `${folder}/g/test.png`);
      await assertFails(uploadBytes(target, new Uint8Array([1,2,3])));
      await assertFails(getMetadata(target));
    }
  }
});
test('deleted group IDs cannot be reclaimed to read retained private archives', async () => {
  await assertSucceeds(update(ref(db('owner')), {'groups/g': null, 'memberships/g': null}));
  await assertSucceeds(get(ref(db('member'), 'groups/g')));
  await assertFails(set(ref(db('outside'), 'groups/g'), {ownerId:'outside', name:'Reclaimed'}));
});
test('rating backend succeeds against real RTDB transactions while direct clients stay blocked', async () => {
  const handle = createRatingHandler({db:admin.database(), bucket:{}});
  const request = (action, fields = {}, uid = 'owner') => ({auth:{uid}, data:{groupId:'g',moduleId:'integration',action,...fields}});
  await handle(request('configure', {revision:0, config:{title:'Coffee',itemTypeName:'Coffee',primaryLabel:'Score',min:0,max:10,criteria:[],metadataFields:[]}}));
  await handle(request('saveItem', {id:'one',version:0,configRevision:1,item:{title:'Espresso'},review:{primaryRating:8}}));
  await handle(request('review', {id:'one',configRevision:1,reviewVersion:0,review:{primaryRating:10}}, 'member'));
  const value = await handle(request('get'));
  require('node:assert/strict').equal(value.module.items.one.reviews.member.primaryRating, 10);
  await assertFails(get(ref(db('owner'),'customRatings/g/integration')));
});
