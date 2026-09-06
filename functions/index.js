const admin = require('firebase-admin');
const functions = require('firebase-functions/v1');
const OpenAI = require('openai');
const crypto = require('crypto');

admin.initializeApp();

const backgroundStyles = new Set([
  'Cinematic',
  'Minimalist',
  'Cyberpunk',
  'Watercolor',
  'Pixel Art',
  'Abstract',
]);

/**
 * Generates a group background through OpenAI and stores it in our own bucket.
 * The OpenAI key is injected at deploy time as a Firebase secret, never sent to
 * the browser or bundled into the Flutter app.
 */
exports.generateGroupBackground = functions
  .runWith({
    secrets: ['OPENAI_API_KEY'],
    timeoutSeconds: 120,
    memory: '1GB',
  })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in before generating a background.',
      );
    }

    const groupId = typeof data?.groupId === 'string' ? data.groupId : '';
    const prompt = typeof data?.prompt === 'string' ? data.prompt.trim() : '';
    const style = typeof data?.style === 'string' ? data.style : 'Cinematic';
    if (!groupId || !prompt || prompt.length > 500) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Provide a group and a background description of up to 500 characters.',
      );
    }

    const groupSnapshot = await admin.database().ref(`groups/${groupId}`).once('value');
    const group = groupSnapshot.val();
    if (!group || group.ownerId !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only the space owner can change its background.',
      );
    }

    const openai = new OpenAI({apiKey: process.env.OPENAI_API_KEY});
    const image = await openai.images.generate({
      model: 'gpt-image-1',
      prompt: `Create a polished, inviting group workspace background. Style: ${
        backgroundStyles.has(style) ? style : 'Cinematic'
      }. Subject: ${prompt}. No words, letters, logos, interfaces, watermarks, or people. Keep the composition calm enough that white header text remains readable.`,
      size: '1024x1024',
      quality: 'medium',
    });

    const base64 = image.data?.[0]?.b64_json;
    if (!base64) {
      throw new functions.https.HttpsError(
        'internal',
        'OpenAI did not return an image.',
      );
    }

    const imagePath = `group_backgrounds/${groupId}/ai/${Date.now()}-${crypto.randomUUID()}.png`;
    const downloadToken = crypto.randomUUID();
    const bucket = admin.storage().bucket();
    await bucket.file(imagePath).save(Buffer.from(base64, 'base64'), {
      metadata: {
        contentType: 'image/png',
        metadata: {firebaseStorageDownloadTokens: downloadToken},
      },
    });

    const encodedPath = encodeURIComponent(imagePath);
    return {
      imageUrl: `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${downloadToken}`,
    };
  });

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
      android: {
        notification: {
          channelId: 'high_importance_channel',
          priority: 'high',
        },
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
