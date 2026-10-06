// Generate the explicit rules file; no rule grants access at the root.
const fs = require('node:fs');
const path = require('node:path');
const owner = "root.child('groups').child($group).child('ownerId').val() === auth.uid";
const member = `auth != null && (${owner} || root.child('memberships').child($group).child(auth.uid).exists())`;
const rules = {'.read': false, '.write': false};
const unusedGroupId = ['customRatings','calendarBox','messages','postits','files','gallery','groupTasks','groupPolls','groupProposals','memberships']
  .map(node => `!root.child('${node}').child($group).exists()`).join(' && ');
rules.groups = {$group: {
  '.read': `auth != null && (!data.exists() || (${owner} || root.child('memberships').child($group).child(auth.uid).exists()))`,
  '.write': `auth != null && ((!data.exists() && newData.child('ownerId').val() === auth.uid && ${unusedGroupId}) || data.child('ownerId').val() === auth.uid)`,
  '.validate': "newData.hasChildren(['name','ownerId']) && newData.child('name').isString() && newData.child('name').val().length > 0 && newData.child('name').val().length <= 160 && (!data.exists() || newData.child('ownerId').val() === data.child('ownerId').val())",
  name: {'.read': 'auth != null'},
}};
rules.memberships = {$group: {
  '.read': member,
  '.write': `auth != null && ${owner} && !newData.exists()`,
  $uid: {
    '.read': 'auth != null && auth.uid === $uid',
    '.write': `auth != null && (${owner} || (auth.uid === $uid && (!newData.exists() || (root.child('groups').child($group).exists() && ((!data.exists() && newData.child('role').val() === 'member') || (data.exists() && newData.child('role').val() === data.child('role').val()))))))`,
    '.validate': "newData.hasChildren(['role','joinedAt']) && (newData.child('role').val() === 'member' || newData.child('role').val() === 'admin' || newData.child('role').val() === 'owner')",
  },
}};
rules.userGroups = {$uid: {'.read': 'auth != null && auth.uid === $uid', $group: {
  '.write': `auth != null && ((auth.uid === $uid && (!newData.exists() || newData.parent().parent().parent().child('memberships').child($group).child($uid).exists() || ${owner})) || (${owner} && !newData.exists()))`,
  '.validate': 'newData.val() === true',
}}};
for (const node of ['profiles', 'users']) {
  rules[node] = {$uid: {
    '.read': 'auth != null',
    '.write': 'auth != null && auth.uid === $uid && newData.exists()',
    isAdmin: {'.validate': "newData.val() === data.val() || (!data.exists() && newData.val() === false) || (!data.exists() && newData.val() === true && root.child('users').child($uid).child('isAdmin').val() === true)"},
    '.validate': "!data.child('isAdmin').exists() || newData.child('isAdmin').val() === data.child('isAdmin').val()",
  }};
}
rules.usernames = {$name: {
  '.read': 'auth != null',
  '.write': 'auth != null && ((!data.exists() && newData.val() === auth.uid) || (data.val() === auth.uid && (!newData.exists() || newData.val() === auth.uid)))',
}};
rules.deviceTokens = {$uid: {'.read': 'auth != null && auth.uid === $uid', '.write': 'auth != null && auth.uid === $uid'}};
for (const [node, author] of [['messages','senderId'], ['postits','senderId'], ['files','senderId'], ['gallery','uploaderId']]) {
  rules[node] = {$group: {
    '.read': member,
    '.write': `auth != null && ${owner} && !newData.exists()`,
    $item: {
      '.write': `${member} && ((!data.exists() && newData.child('${author}').val() === auth.uid) || data.child('${author}').val() === auth.uid || ${owner})`,
      '.validate': `newData.child('${author}').isString() && (!data.exists() || newData.child('${author}').val() === data.child('${author}').val())`,
    },
  }};
}
rules.groupTasks = {$group: {'.read': member, $item: {
  '.write': `${member} && ((!data.exists() && newData.child('creatorId').val() === auth.uid) || data.child('creatorId').val() === auth.uid || ${owner})`,
  '.validate': "newData.hasChildren(['title','creatorId','isDone']) && (!data.exists() || newData.child('creatorId').val() === data.child('creatorId').val())",
  isDone: {'.write': `${member} && data.parent().exists()`, '.validate': 'newData.isBoolean()'},
}}};
rules.groupPolls = {$group: {'.read': member, $item: {
  '.write': `${member} && !data.exists() && newData.child('creatorId').val() === auth.uid && !newData.child('votes').exists()`,
  '.validate': "newData.hasChildren(['question','creatorId','options','closesAt','isClosed'])",
  isClosed: {'.write': `${member} && (data.parent().child('creatorId').val() === auth.uid || ${owner})`, '.validate': 'newData.isBoolean()'},
  votes: {$uid: {'.write': `${member} && auth.uid === $uid && data.parent().parent().child('isClosed').val() !== true && data.parent().parent().child('closesAt').val() > now`, '.validate': "newData.isString() && data.parent().parent().child('options').child(newData.val()).exists()"}},
}}};
// Legacy gathering planner stores each date's votes as a shared array. Preserve
// its collaborative semantics while preventing any cross-group access.
rules.groupProposals = {$group: {'.read': member, '.write': member}};
const participant = "auth != null && root.child('directConversations').child($conversation).child('participants').child(auth.uid).val() === true";
rules.directConversations = {$conversation: {'.read': `${participant} || (auth != null && !data.exists() && ($conversation.beginsWith(auth.uid + '__') || $conversation.endsWith('__' + auth.uid)))`}};
rules.directMessages = {$conversation: {'.read': `${participant} || (auth != null && !root.child('directConversations').child($conversation).exists() && ($conversation.beginsWith(auth.uid + '__') || $conversation.endsWith('__' + auth.uid)))`}};
rules.userDirectChats = {$uid: {'.read': 'auth != null && auth.uid === $uid'}};
// DM writes, rating, calendar imports, and upload counters are server-only.
for (const node of ['customRatings', 'calendarBox', 'calendarBoxUsage', 'workspaceUploadUsage']) rules[node] = {'.read': false, '.write': false};
const admin = "(root.child('profiles').child(auth.uid).child('isAdmin').val() === true || root.child('users').child(auth.uid).child('isAdmin').val() === true)";
rules.global_suggestions = {'.read': 'auth != null', $item: {
  '.write': `auth != null && ((!data.exists() && newData.child('authorId').val() === auth.uid) || data.child('authorId').val() === auth.uid || ${admin})`,
  '.validate': "newData.child('authorId').isString() && (!data.exists() || newData.child('authorId').val() === data.child('authorId').val())",
}};
const result = JSON.stringify({rules}, null, 2) + '\n';
const destination = path.join(__dirname, '..', 'database.rules.json');
if (process.argv.includes('--check')) {
  if (fs.readFileSync(destination, 'utf8').replace(/\r\n/g, '\n') !== result) throw Error('Regenerate database.rules.json');
} else fs.writeFileSync(destination, result);
