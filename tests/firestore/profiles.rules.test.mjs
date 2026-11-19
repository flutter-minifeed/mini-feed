import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  getDocs,
  collection,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';

let env;

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
});

const client = (uid) => env.authenticatedContext(uid, {
  firebase: { sign_in_provider: 'anonymous' },
}).firestore();

const profile = () => ({
  nickName: '밤산책 고양이',
  colorIndex: 4,
  createdAt: serverTimestamp(),
});

async function seed() {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/owner'), {
      ...profile(),
      createdAt: Timestamp.fromMillis(1000),
    });
  });
}

test('익명 사용자는 자신의 프로필을 생성할 수 있다', async () => {
  // given
  const ref = doc(client('owner'), 'users/owner');
  const data = profile();

  // when
  const request = setDoc(ref, data);

  // then
  await assertSucceeds(request);
});

test('익명 사용자는 자신의 프로필을 조회할 수 있다', async () => {
  // given
  await seed();
  const ref = doc(client('owner'), 'users/owner');

  // when
  const request = getDoc(ref);

  // then
  await assertSucceeds(request);
});

for (const [name, createClient] of [
  ['미인증 사용자', () => env.unauthenticatedContext().firestore()],
  ['다른 사용자', () => client('other')],
]) {
  test(`${name}는 소유자의 프로필을 조회할 수 없다`, async () => {
    // given
    await seed();
    const ref = doc(createClient(), 'users/owner');

    // when
    const request = getDoc(ref);

    // then
    await assertFails(request);
  });

  test(`${name}는 소유자의 프로필을 생성할 수 없다`, async () => {
    // given
    const ref = doc(createClient(), 'users/owner');
    const data = profile();

    // when
    const request = setDoc(ref, data);

    // then
    await assertFails(request);
  });
}

for (const [name, changes] of [
  ['닉네임', { nickName: '차분한 토끼' }],
  ['색상', { colorIndex: 2 }],
  ['생성 시각', { createdAt: serverTimestamp() }],
]) {
  test(`소유자도 프로필의 ${name}을 변경할 수 없다`, async () => {
    // given
    await seed();
    const ref = doc(client('owner'), 'users/owner');

    // when
    const request = updateDoc(ref, changes);

    // then
    await assertFails(request);
  });
}

test('소유자도 프로필을 삭제할 수 없다', async () => {
  // given
  await seed();
  const ref = doc(client('owner'), 'users/owner');

  // when
  const request = deleteDoc(ref);

  // then
  await assertFails(request);
});

test('프로필 목록을 조회할 수 없다', async () => {
  // given
  await seed();
  const ref = collection(client('owner'), 'users');

  // when
  const request = getDocs(ref);

  // then
  await assertFails(request);
});

for (const [name, path, data] of [
  ['미구현 게시글', 'posts/example', { body: '글' }],
  ['프로필 하위 경로', 'users/owner/extra/example', { value: 1 }],
]) {
  test(`${name}는 조회할 수 없다`, async () => {
    // given
    const ref = doc(client('owner'), path);

    // when
    const request = getDoc(ref);

    // then
    await assertFails(request);
  });

  test(`${name}에는 문서를 생성할 수 없다`, async () => {
    // given
    const ref = doc(client('owner'), path);

    // when
    const request = setDoc(ref, data);

    // then
    await assertFails(request);
  });
}

for (const [colorIndex, allowed] of [
  [0, true],
  [7, true],
  [-1, false],
  [8, false],
]) {
  test(`색상 ${colorIndex}의 프로필 생성은 ${allowed ? '허용' : '거부'}된다`, async () => {
    // given
    const ref = doc(client('owner'), 'users/owner');
    const data = { ...profile(), colorIndex };
    const assertResult = allowed ? assertSucceeds : assertFails;

    // when
    const request = setDoc(ref, data);

    // then
    await assertResult(request);
  });
}

for (const [name, data] of [
  ['추가 필드', { ...profile(), extra: true }],
  ['공백 닉네임', { ...profile(), nickName: '   ' }],
  ['문자열 색상', { ...profile(), colorIndex: '4' }],
  ['클라이언트 생성 시각', { ...profile(), createdAt: Timestamp.fromMillis(1000) }],
  ['생성 시각 누락', { nickName: '밤산책 고양이', colorIndex: 4 }],
]) {
  test(`${name} 조건에서는 프로필 생성이 거부된다`, async () => {
    // given
    const ref = doc(client('owner'), 'users/owner');

    // when
    const request = setDoc(ref, data);

    // then
    await assertFails(request);
  });
}

test('비익명 사용자는 자신의 프로필도 생성할 수 없다', async () => {
  // given
  const db = env.authenticatedContext('owner', {
    firebase: { sign_in_provider: 'password' },
  }).firestore();
  const ref = doc(db, 'users/owner');
  const data = profile();

  // when
  const request = setDoc(ref, data);

  // then
  await assertFails(request);
});
