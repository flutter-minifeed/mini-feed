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
const userA = 'like-user-a';
const userB = 'like-user-b';
const postId = 'liked-post';

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
    await setDoc(postRef(context.firestore()), {
      authorId: 'writer',
      nickName: '밤산책 고양이',
      colorIndex: 4,
      body: '좋아요를 받을 글',
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
const likeRef = (db, uid) => doc(db, 'posts', postId, 'likes', uid);

// 앱의 FirestoreLikeRepository와 같은 순서로 글과 내 좋아요를 읽고 함께 바꾼다.
function setLike(db, uid, liked) {
  return runTransaction(db, async (transaction) => {
    const post = await transaction.get(postRef(db));
    const like = await transaction.get(likeRef(db, uid));
    if (!post.exists() || like.exists() === liked) return;
    if (liked) {
      transaction.set(likeRef(db, uid), { createdAt: serverTimestamp() });
    } else {
      transaction.delete(likeRef(db, uid));
    }
    transaction.update(postRef(db), { likeCount: increment(liked ? 1 : -1) });
  });
}

// 이미 누른 상태를 규칙 밖에서 만들어 취소·중복 요청을 검사한다.
async function seedLikes(...uids) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const batch = writeBatch(db);
    for (const uid of uids) {
      batch.set(likeRef(db, uid), { createdAt: Timestamp.fromMillis(2000) });
    }
    batch.update(postRef(db), { likeCount: uids.length });
    await batch.commit();
  });
}

async function serverState() {
  let state;
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const post = await getDoc(postRef(db));
    const likes = await getDocs(collection(db, 'posts', postId, 'likes'));
    state = {
      likeCount: post.data().likeCount,
      likedBy: likes.docs.map((like) => like.id).sort(),
    };
  });
  return state;
}

test('본인 좋아요 문서와 likeCount +1을 같은 작업으로 쓰면 허용된다', async () => {
  // given
  const db = authenticated(userA);

  // when
  const request = setLike(db, userA, true);

  // then
  await assertSucceeds(request);
  assert.deepEqual(await serverState(), { likeCount: 1, likedBy: [userA] });
});

test('본인 좋아요 문서 삭제와 likeCount -1을 같은 작업으로 쓰면 허용된다', async () => {
  // given
  await seedLikes(userA);
  const db = authenticated(userA);

  // when
  const request = setLike(db, userA, false);

  // then
  await assertSucceeds(request);
  assert.deepEqual(await serverState(), { likeCount: 0, likedBy: [] });
});

test('미인증 사용자는 좋아요를 누를 수 없다', async () => {
  // given
  const db = env.unauthenticatedContext().firestore();
  const batch = writeBatch(db);
  batch.set(likeRef(db, userA), { createdAt: serverTimestamp() });
  batch.update(postRef(db), { likeCount: 1 });

  // when
  const request = batch.commit();

  // then
  await assertFails(request);
});

test('다른 UID의 좋아요 문서를 만들면 개수를 함께 올려도 거부된다', async () => {
  // given
  const db = authenticated(userB);
  const batch = writeBatch(db);
  batch.set(likeRef(db, userA), { createdAt: serverTimestamp() });
  batch.update(postRef(db), { likeCount: 1 });

  // when
  const request = batch.commit();

  // then
  await assertFails(request);
});

test('이미 누른 좋아요를 다시 쓰면서 개수를 올리면 거부된다', async () => {
  // given
  await seedLikes(userA);
  const db = authenticated(userA);
  const batch = writeBatch(db);
  batch.set(likeRef(db, userA), { createdAt: serverTimestamp() });
  batch.update(postRef(db), { likeCount: 2 });

  // when
  const request = batch.commit();

  // then
  await assertFails(request);
  assert.deepEqual(await serverState(), { likeCount: 1, likedBy: [userA] });
});

test('좋아요 문서 없이 likeCount만 올리면 거부된다', async () => {
  // given
  const db = authenticated(userA);

  // when
  const request = updateDoc(postRef(db), { likeCount: 1 });

  // then
  await assertFails(request);
});

test('좋아요 문서만 만들고 likeCount를 올리지 않으면 거부된다', async () => {
  // given
  const db = authenticated(userA);

  // when
  const request = setDoc(likeRef(db, userA), { createdAt: serverTimestamp() });

  // then
  await assertFails(request);
});

test('누르지 않은 글의 likeCount를 내려 음수로 만들 수 없다', async () => {
  // given
  const db = authenticated(userA);
  const batch = writeBatch(db);
  batch.delete(likeRef(db, userA));
  batch.update(postRef(db), { likeCount: -1 });

  // when
  const request = batch.commit();

  // then
  await assertFails(request);
  assert.deepEqual(await serverState(), { likeCount: 0, likedBy: [] });
});

for (const [name, postChange] of [
  ['개수를 2 올리는', { likeCount: 2 }],
  ['본문을 함께 바꾸는', { likeCount: 1, body: '바뀐 본문' }],
  ['개수를 정수가 아닌 값으로 바꾸는', { likeCount: 1.5 }],
]) {
  test(`좋아요와 함께 ${name} 요청은 거부된다`, async () => {
    // given
    const db = authenticated(userA);
    const batch = writeBatch(db);
    batch.set(likeRef(db, userA), { createdAt: serverTimestamp() });
    batch.update(postRef(db), postChange);

    // when
    const request = batch.commit();

    // then
    await assertFails(request);
  });
}

for (const [name, likeData] of [
  ['정해지지 않은 필드가 있는', { createdAt: serverTimestamp(), uid: userA }],
  ['기기 시각을 넣은', { createdAt: Timestamp.fromMillis(1000) }],
]) {
  test(`${name} 좋아요 문서는 거부된다`, async () => {
    // given
    const db = authenticated(userA);
    const batch = writeBatch(db);
    batch.set(likeRef(db, userA), likeData);
    batch.update(postRef(db), { likeCount: 1 });

    // when
    const request = batch.commit();

    // then
    await assertFails(request);
  });
}

test('없는 게시글에는 좋아요 문서를 만들 수 없다', async () => {
  // given
  const db = authenticated(userA);
  const ref = doc(db, 'posts', 'missing-post', 'likes', userA);

  // when
  const request = setDoc(ref, { createdAt: serverTimestamp() });

  // then
  await assertFails(request);
});

test('본인 좋아요 문서는 읽을 수 있고 다른 사용자의 문서는 읽을 수 없다', async () => {
  // given
  await seedLikes(userA);

  // when
  // 요청을 미리 만들어 두면 기다리는 사이 거부가 처리되지 않은 오류로 잡혀서 차례로 보낸다.
  const readOwn = () => getDoc(likeRef(authenticated(userA), userA));
  const readOther = () => getDoc(likeRef(authenticated(userB), userA));

  // then
  await assertSucceeds(readOwn());
  await assertFails(readOther());
});

test('좋아요 목록은 누른 사람이라도 조회할 수 없다', async () => {
  // given
  await seedLikes(userA, userB);
  const db = authenticated(userA);

  // when
  const request = getDocs(collection(db, 'posts', postId, 'likes'));

  // then
  await assertFails(request);
});

test('두 사용자가 동시에 좋아요를 누르면 두 문서와 likeCount 2가 남는다', async () => {
  // given
  const a = authenticated(userA);
  const b = authenticated(userB);

  // when
  await Promise.all([setLike(a, userA, true), setLike(b, userB, true)]);

  // then
  assert.deepEqual(await serverState(), { likeCount: 2, likedBy: [userA, userB] });
});

test('같은 사용자가 좋아요를 동시에 여러 번 보내도 한 번만 센다', async () => {
  // given
  const db = authenticated(userA);

  // when
  const results = await Promise.allSettled([
    setLike(db, userA, true),
    setLike(db, userA, true),
    setLike(db, userA, true),
  ]);

  // then
  assert.ok(results.some((result) => result.status === 'fulfilled'));
  assert.deepEqual(await serverState(), { likeCount: 1, likedBy: [userA] });
});

test('두 사용자가 좋아요·취소를 빠르게 이어 보내면 마지막 상태대로 개수가 맞는다', async () => {
  // given
  const a = authenticated(userA);
  const b = authenticated(userB);
  const toggle = async (db, uid, states) => {
    for (const liked of states) await setLike(db, uid, liked);
  };

  // when
  await Promise.all([
    toggle(a, userA, [true, false, true]),
    toggle(b, userB, [true, false, true, false]),
  ]);

  // then
  assert.deepEqual(await serverState(), { likeCount: 1, likedBy: [userA] });
});
