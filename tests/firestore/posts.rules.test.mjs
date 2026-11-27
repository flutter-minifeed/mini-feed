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
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

let env;
const writer = 'writer-a';
const reader = 'reader-b';
const author = { nickName: '밤산책 고양이', colorIndex: 4 };

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
    await setDoc(doc(context.firestore(), 'users', writer), {
      ...author,
      createdAt: Timestamp.fromMillis(1000),
    });
  });
});

function authenticated(uid = writer) {
  return env.authenticatedContext(uid, {
    firebase: { sign_in_provider: 'anonymous' },
  }).firestore();
}

function post(overrides = {}) {
  return {
    authorId: writer,
    ...author,
    body: '첫 게시글',
    createdAt: serverTimestamp(),
    likeCount: 0,
    commentCount: 0,
    ...overrides,
  };
}

const postRef = (db) => doc(db, 'posts', 'example');

async function seedPost() {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(postRef(context.firestore()), {
      ...post(),
      createdAt: Timestamp.fromMillis(1000),
    });
  });
}

test('인증 사용자로 다른 작성자의 게시글을 조회할 수 있다', async () => {
  // given
  await seedPost();
  const ref = postRef(authenticated(reader));

  // when
  const request = getDoc(ref);

  // then
  await assertSucceeds(request);
});

test('인증 사용자는 게시글 목록을 조회할 수 있다', async () => {
  // given
  await seedPost();
  const ref = collection(authenticated(reader), 'posts');

  // when
  const request = getDocs(ref);

  // then
  await assertSucceeds(request);
});

test('미인증 사용자는 게시글을 조회할 수 없다', async () => {
  // given
  await seedPost();
  const ref = postRef(env.unauthenticatedContext().firestore());

  // when
  const request = getDoc(ref);

  // then
  await assertFails(request);
});

test('미인증 사용자는 게시글 목록을 조회할 수 없다', async () => {
  // given
  await seedPost();
  const ref = collection(env.unauthenticatedContext().firestore(), 'posts');

  // when
  const request = getDocs(ref);

  // then
  await assertFails(request);
});

test('미인증 사용자는 새 게시글을 만들 수 없다', async () => {
  // given
  const ref = postRef(env.unauthenticatedContext().firestore());

  // when
  const request = setDoc(ref, post());

  // then
  await assertFails(request);
});

for (const [name, change] of [
  ['다른 UID', { authorId: reader }],
  ['프로필과 다른 닉네임', { nickName: '다른 닉네임' }],
  ['프로필과 다른 색상', { colorIndex: 3 }],
  ['정수 타입이 아닌 색상', { colorIndex: '4' }],
  ['허용하지 않은 필드', { likedByMe: false }],
  ['문자열이 아닌 본문', { body: 5 }],
  ['클라이언트 작성 시각', { createdAt: Timestamp.fromMillis(1000) }],
  ['Timestamp 타입이 아닌 작성 시각', { createdAt: '2026-11-19' }],
  ['0이 아닌 초기 좋아요 수', { likeCount: 1 }],
  ['0이 아닌 초기 댓글 수', { commentCount: -1 }],
  ['문자열 카운터', { likeCount: '0' }],
]) {
  test(name + '이면 게시글 생성이 거부된다', async () => {
    // given
    const ref = postRef(authenticated());

    // when
    const request = setDoc(ref, post(change));

    // then
    await assertFails(request);
  });
}

test('필수 필드를 하나라도 누락하면 게시글 생성이 거부된다', async () => {
  // given
  const ref = postRef(authenticated());
  const { commentCount, ...incomplete } = post();

  // when
  const request = setDoc(ref, incomplete);

  // then
  await assertFails(request);
});

test('작성자 프로필이 없으면 게시글 생성이 거부된다', async () => {
  // given
  const ref = postRef(authenticated(reader));

  // when
  const request = setDoc(ref, post({ authorId: reader }));

  // then
  await assertFails(request);
});

for (const [name, uid] of [['작성자', writer], ['다른 사용자', reader]]) {
  test(name + '는 게시글 본문을 수정할 수 없다', async () => {
    // given
    await seedPost();
    const ref = postRef(authenticated(uid));

    // when
    const request = updateDoc(ref, { body: '수정한 글' });

    // then
    await assertFails(request);
  });

  test(name + '는 삭제 기록 없이 게시글만 삭제할 수 없다', async () => {
    // given
    await seedPost();
    const ref = postRef(authenticated(uid));

    // when
    const request = deleteDoc(ref);

    // then
    await assertFails(request);
  });
}

const commentsRef = (db) => collection(postRef(db), 'comments');
const commentRef = (db) => doc(commentsRef(db), 'comment-1');

async function seedComment() {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(commentRef(context.firestore()), {
      authorId: writer,
      body: '테스트 댓글',
      createdAt: Timestamp.fromMillis(2000),
    });
  });
}

test('인증 사용자가 댓글 없는 게시글을 열면 댓글 조회는 빈 목록을 반환한다', async () => {
  // given
  await seedPost();
  const db = authenticated(reader);
  const postSnapshot = await assertSucceeds(getDoc(postRef(db)));
  assert.equal(postSnapshot.exists(), true);

  // when
  const request = getDocs(query(collection(postSnapshot.ref, 'comments'), orderBy('createdAt')));

  // then
  const snapshot = await assertSucceeds(request);
  assert.equal(snapshot.size, 0);
});

test('인증 사용자는 기존 게시글의 댓글 목록을 읽을 수 있다', async () => {
  // given
  await seedPost();
  await seedComment();
  const ref = query(commentsRef(authenticated(reader)), orderBy('createdAt'));

  // when
  const request = getDocs(ref);

  // then
  const snapshot = await assertSucceeds(request);
  assert.deepEqual(snapshot.docs.map((item) => item.id), ['comment-1']);
});

test('인증 사용자는 기존 게시글의 댓글 한 건을 읽을 수 있다', async () => {
  // given
  await seedPost();
  await seedComment();
  const ref = commentRef(authenticated(reader));

  // when
  const request = getDoc(ref);

  // then
  const snapshot = await assertSucceeds(request);
  assert.equal(snapshot.data().body, '테스트 댓글');
});

test('미인증 사용자는 기존 게시글의 댓글 목록을 읽을 수 없다', async () => {
  // given
  await seedPost();
  await seedComment();
  const ref = commentsRef(env.unauthenticatedContext().firestore());

  // when
  const request = getDocs(ref);

  // then
  await assertFails(request);
});

test('인증 사용자도 게시글이 없는 댓글 목록은 읽을 수 없다', async () => {
  // given
  await seedComment();
  const ref = commentsRef(authenticated(reader));

  // when
  const request = getDocs(ref);

  // then
  await assertFails(request);
});

test('인증 사용자도 댓글을 만들 수 없다', async () => {
  // given
  await seedPost();
  const ref = commentRef(authenticated());

  // when
  const request = setDoc(ref, { authorId: writer, body: '댓글' });

  // then
  await assertFails(request);
});

test('인증된 댓글 작성자도 댓글을 수정할 수 없다', async () => {
  // given
  await seedPost();
  await seedComment();
  const ref = commentRef(authenticated());

  // when
  const request = updateDoc(ref, { body: '수정한 댓글' });

  // then
  await assertFails(request);
});

test('인증된 댓글 작성자도 댓글을 삭제할 수 없다', async () => {
  // given
  await seedPost();
  await seedComment();
  const ref = commentRef(authenticated());

  // when
  const request = deleteDoc(ref);

  // then
  await assertFails(request);
});

for (const path of ['posts/example/likes/writer-a', 'posts/example/reports/report-1']) {
  test('인증 사용자가 미구현 하위 경로 ' + path + '에 쓰면 거부된다', async () => {
    // given
    await seedPost();
    const ref = doc(authenticated(), path);

    // when
    const request = setDoc(ref, { authorId: writer });

    // then
    await assertFails(request);
  });
}

const family = '\u{1f468}\u200d\u{1f469}\u200d\u{1f467}\u200d\u{1f466}';
for (const [name, body, expected] of [
  ['한글 299자', '가'.repeat(299), true],
  ['한글 300자', '가'.repeat(300), true],
  ['한글 301자', '가'.repeat(301), false],
  ['가족 이모지 299개', family.repeat(299), true],
  ['가족 이모지 300개', family.repeat(300), true],
  ['가족 이모지 301개', family.repeat(301), false],
  ['한글 자모 결합 300자', '\u1100\u1161'.repeat(300), true],
  ['한글 자모 결합 301자', '\u1100\u1161'.repeat(301), false],
  ['국기 이모지 300개', '🇰🇷'.repeat(300), true],
  ['국기 이모지 301개', '🇰🇷'.repeat(301), false],
  ['본문 중간의 줄바꿈까지 300자', family.repeat(298) + '\n끝', true],
  ['본문 중간의 줄바꿈까지 301자', family.repeat(299) + '\n끝', false],
  ['결합 악센트 300자', 'e\u0301'.repeat(300), true],
  ['내부 분류 기호와 같은 원문 301자', '\ue000'.repeat(301), false],
  ['빈 본문', '', false],
  ['공백·탭·줄바꿈으로만 된 본문', ' \t\n', false],
  ['줄 바꿈 방지 공백으로만 된 본문', '\u00a0', false],
]) {
  test(name + '는 ' + (expected ? '허용' : '거부') + '된다', async () => {
    // given
    const ref = postRef(authenticated());
    const payload = post({ body });

    // when
    const request = setDoc(ref, payload);

    // then
    await (expected ? assertSucceeds : assertFails)(request);
  });
}
