import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  increment,
  runTransaction,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let env;
const userA = 'comment-user-a';
const userB = 'comment-user-b';
const profiles = {
  [userA]: { nickName: '밤산책 고양이', colorIndex: 4 },
  [userB]: { nickName: '새벽 펭귄', colorIndex: 2 },
};
const postId = 'commented-post';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-minifeed-auth',
    firestore: {
      rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [uid, profile] of Object.entries(profiles)) {
      await setDoc(doc(db, 'users', uid), {
        ...profile,
        createdAt: Timestamp.fromMillis(500),
      });
    }
    await setDoc(postRef(db), {
      authorId: 'writer',
      nickName: '글쓴이',
      colorIndex: 1,
      body: '댓글을 받을 글',
      createdAt: Timestamp.fromMillis(1000),
      likeCount: 0,
      commentCount: 0,
    });
  });
});

function authenticated(uid) {
  return env.authenticatedContext(uid, {
    firebase: { sign_in_provider: 'anonymous' },
  }).firestore();
}

const postRef = (db) => doc(db, 'posts', postId);
const commentRef = (db, id) => doc(db, 'posts', postId, 'comments', id);

function comment(uid, overrides = {}) {
  return {
    authorId: uid,
    ...profiles[uid],
    body: '좋은 글이네요',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

// 댓글 문서와 게시글 개수·lastCommentId를 한 번에 쓴다. 조작 요청을 만들 때 바꿔 넣는다.
function addBatch(db, uid, id, { data = comment(uid), post = {} } = {}) {
  const batch = writeBatch(db);
  batch.set(commentRef(db, id), data);
  batch.update(postRef(db), { commentCount: increment(1), lastCommentId: id, ...post });
  return batch.commit();
}

// 앱의 FirestoreCommentRepository와 같은 순서로 글과 요청 ID의 댓글을 읽고 함께 쓴다.
function addComment(db, uid, id, body = '좋은 글이네요') {
  return runTransaction(db, async (transaction) => {
    const post = await transaction.get(postRef(db));
    const saved = await transaction.get(commentRef(db, id));
    if (!post.exists() || saved.exists()) return;
    transaction.set(commentRef(db, id), comment(uid, { body }));
    transaction.update(postRef(db), { commentCount: increment(1), lastCommentId: id });
  });
}

async function seedComment(id) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(commentRef(db, id), {
      ...comment(userA),
      createdAt: Timestamp.fromMillis(2000),
    });
    await updateDoc(postRef(db), { commentCount: 1, lastCommentId: id });
  });
}

async function serverState() {
  let state;
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const post = await getDoc(postRef(db));
    const comments = await getDocs(collection(db, 'posts', postId, 'comments'));
    state = {
      commentCount: post.data().commentCount,
      commentIds: comments.docs.map((saved) => saved.id).sort(),
    };
  });
  return state;
}

test('본인 프로필로 쓴 댓글과 commentCount +1을 같은 작업으로 쓰면 허용된다', async () => {
  // given
  const db = authenticated(userA);

  // when
  const request = addComment(db, userA, 'request-1');

  // then
  await assertSucceeds(request);
  assert.deepEqual(await serverState(), { commentCount: 1, commentIds: ['request-1'] });
});

for (const [name, body, expected] of [
  ['한글 200자', '가'.repeat(200), true],
  ['한글 201자', '가'.repeat(201), false],
  ['가족 이모지 200개', '\u{1f468}‍\u{1f469}‍\u{1f467}‍\u{1f466}'.repeat(200), true],
  ['가족 이모지 201개', '\u{1f468}‍\u{1f469}‍\u{1f467}‍\u{1f466}'.repeat(201), false],
  ['빈 본문', '', false],
  ['공백·줄바꿈으로만 된 본문', ' \n\t ', false],
]) {
  test(`${name} 댓글은 ${expected ? '허용' : '거부'}된다`, async () => {
    // given
    const db = authenticated(userA);

    // when
    const request = addBatch(db, userA, 'request-1', { data: comment(userA, { body }) });

    // then
    await (expected ? assertSucceeds(request) : assertFails(request));
  });
}

test('미인증 사용자는 댓글을 쓸 수 없다', async () => {
  // given
  const db = env.unauthenticatedContext().firestore();

  // when
  const request = addBatch(db, userA, 'request-1');

  // then
  await assertFails(request);
});

for (const [name, data] of [
  ['다른 UID를 작성자로 적은', comment(userB, { ...profiles[userA] })],
  ['프로필과 다른 닉네임을 적은', comment(userA, { nickName: '다른 이름' })],
  ['프로필과 다른 색상을 적은', comment(userA, { colorIndex: 0 })],
  ['기기 시각을 넣은', comment(userA, { createdAt: Timestamp.fromMillis(3000) })],
  ['정해지지 않은 필드가 있는', comment(userA, { postId })],
  ['문자열이 아닌 본문을 넣은', comment(userA, { body: 1 })],
]) {
  test(`${name} 댓글은 거부된다`, async () => {
    // given
    const db = authenticated(userA);

    // when
    const request = addBatch(db, userA, 'request-1', { data });

    // then
    await assertFails(request);
    assert.deepEqual(await serverState(), { commentCount: 0, commentIds: [] });
  });
}

test('댓글 없이 commentCount만 올리면 거부된다', async () => {
  // given
  const db = authenticated(userA);

  // when
  const request = updateDoc(postRef(db), { commentCount: 1, lastCommentId: 'request-1' });

  // then
  await assertFails(request);
});

test('이미 있는 댓글 ID를 적어 commentCount만 올리면 거부된다', async () => {
  // given
  await seedComment('old-comment');
  const db = authenticated(userA);

  // when
  const request = updateDoc(postRef(db), {
    commentCount: increment(1),
    lastCommentId: 'old-comment',
  });

  // then
  await assertFails(request);
  assert.deepEqual(await serverState(), { commentCount: 1, commentIds: ['old-comment'] });
});

test('댓글만 만들고 commentCount를 올리지 않으면 거부된다', async () => {
  // given
  const db = authenticated(userA);

  // when
  const request = setDoc(commentRef(db, 'request-1'), comment(userA));

  // then
  await assertFails(request);
});

for (const [name, post] of [
  ['개수를 2 올리는', { commentCount: 2 }],
  ['lastCommentId를 다른 ID로 적는', { lastCommentId: 'other-comment' }],
  ['본문을 함께 바꾸는', { body: '바뀐 본문' }],
  ['좋아요 수를 함께 바꾸는', { likeCount: 1 }],
]) {
  test(`댓글과 함께 ${name} 요청은 거부된다`, async () => {
    // given
    const db = authenticated(userA);

    // when
    const request = addBatch(db, userA, 'request-1', { post });

    // then
    await assertFails(request);
  });
}

test('이미 있는 댓글을 다시 쓰면서 개수를 올리면 거부된다', async () => {
  // given
  await seedComment('request-1');
  const db = authenticated(userA);

  // when
  const request = addBatch(db, userA, 'request-1');

  // then
  await assertFails(request);
  assert.deepEqual(await serverState(), { commentCount: 1, commentIds: ['request-1'] });
});

test('없는 게시글에는 댓글을 쓸 수 없다', async () => {
  // given
  const db = authenticated(userA);
  const ref = doc(db, 'posts', 'missing-post', 'comments', 'request-1');

  // when
  const request = setDoc(ref, comment(userA));

  // then
  await assertFails(request);
});

test('두 사용자가 동시에 댓글을 쓰면 두 댓글과 commentCount 2가 남는다', async () => {
  // given
  const a = authenticated(userA);
  const b = authenticated(userB);

  // when
  await Promise.all([
    addComment(a, userA, 'request-a'),
    addComment(b, userB, 'request-b'),
  ]);

  // then
  assert.deepEqual(await serverState(), {
    commentCount: 2,
    commentIds: ['request-a', 'request-b'],
  });
});

test('같은 요청 ID로 여러 번 동시에 보내도 댓글과 개수는 한 번만 늘어난다', async () => {
  // given
  const db = authenticated(userA);

  // when
  const results = await Promise.allSettled([
    addComment(db, userA, 'request-1'),
    addComment(db, userA, 'request-1'),
    addComment(db, userA, 'request-1'),
  ]);

  // then
  assert.ok(results.some((result) => result.status === 'fulfilled'));
  assert.deepEqual(await serverState(), { commentCount: 1, commentIds: ['request-1'] });
});

test('좋아요와 댓글이 같은 글에 동시에 들어오면 두 개수가 모두 맞는다', async () => {
  // given
  const a = authenticated(userA);
  const b = authenticated(userB);
  const like = runTransaction(a, async (transaction) => {
    await transaction.get(postRef(a));
    const likeRef = doc(a, 'posts', postId, 'likes', userA);
    if ((await transaction.get(likeRef)).exists()) return;
    transaction.set(likeRef, { createdAt: serverTimestamp() });
    transaction.update(postRef(a), { likeCount: increment(1) });
  });

  // when
  await Promise.all([like, addComment(b, userB, 'request-b')]);

  // then
  let post;
  await env.withSecurityRulesDisabled(async (context) => {
    post = (await getDoc(postRef(context.firestore()))).data();
  });
  assert.equal(post.likeCount, 1);
  assert.equal(post.commentCount, 1);
});
