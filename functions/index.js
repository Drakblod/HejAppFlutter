const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');

admin.initializeApp();

exports.onMessageCreated = functions.database
  .ref('/messages/{groupId}/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.val();
    if (!message) return null;

    const { groupId } = context.params;
    const senderId = message.senderId || '';

    // Load group meta for nicer titles.
    const groupSnap = await admin
      .database()
      .ref(`/groups/${groupId}/name`)
      .once('value');
    const groupName = groupSnap.val() || 'Group';

    // Fetch members of this group.
    const memberSnap = await admin
      .database()
      .ref(`/memberships/${groupId}`)
      .once('value');

    const members = memberSnap.val();
    if (!members) return null;

    const tokens = new Set();

    for (const memberId of Object.keys(members)) {
      if (memberId === senderId) continue;

      const devicesSnap = await admin
        .database()
        .ref(`/deviceTokens/${memberId}`)
        .once('value');

      devicesSnap.forEach(child => {
        const token = child.val()?.token;
        if (token) tokens.add(token);
      });
    }

    if (!tokens.size) return null;

    const title = `${message.senderName || 'New message'} in ${groupName}`;
    const body = (message.text || '(no message)').slice(0, 120);

    const payload = {
      notification: { title, body },
      data: {
        groupId: groupId || '',
        messageId: context.params.messageId || '',
        senderId,
      },
    };

    try {
      await admin.messaging().sendEachForMulticast({
        tokens: Array.from(tokens),
        notification: payload.notification,
        data: payload.data,
      });
      console.log(`Sent notifications to ${tokens.size} tokens for group ${groupId}`);
    } catch (error) {
      console.error('Error sending multicast message:', error);
    }

    return null;
  });
