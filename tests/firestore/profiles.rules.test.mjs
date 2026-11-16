import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, getDocs, collection, setDoc, updateDoc, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-minifeed-auth',
    firestore: { rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const client = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const profile = () => ({ nickName: '밤산책 고양이', colorIndex: 4, createdAt: serverTimestamp() });
async function seed() {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'users/owner'), { ...profile(), createdAt: Timestamp.fromMillis(1000) });
  });
}

test('익명 사용자는 자신의 프로필을 생성하고 조회할 수 있다', async () => {
  const ref = doc(client('owner'), 'users/owner');
  await assertSucceeds(setDoc(ref, profile()));
  await assertSucceeds(getDoc(ref));
});
test('미인증 사용자와 다른 사용자는 프로필을 읽거나 생성할 수 없다', async () => {
  await seed();
  for (const db of [env.unauthenticatedContext().firestore(), client('other')]) {
    await assertFails(getDoc(doc(db, 'users/owner')));
    await assertFails(setDoc(doc(db, 'users/new-user'), profile()));
  }
});
test('소유자도 닉네임·색·시각을 바꾸거나 프로필을 삭제할 수 없다', async () => {
  await seed();
  const ref = doc(client('owner'), 'users/owner');
  await assertFails(updateDoc(ref, { nickName: '차분한 토끼' }));
  await assertFails(updateDoc(ref, { colorIndex: 2 }));
  await assertFails(updateDoc(ref, { createdAt: serverTimestamp() }));
  await assertFails(deleteDoc(ref));
});
test('프로필 목록과 미구현 게시글·하위 경로는 접근할 수 없다', async () => {
  const db = client('owner');
  await assertFails(getDocs(collection(db, 'users')));
  await assertFails(setDoc(doc(db, 'posts/example'), { body: '글' }));
  await assertFails(setDoc(doc(db, 'users/owner/extra/example'), { value: 1 }));
});
test('잘못된 필드·타입·색·클라이언트 시각과 비익명 사용자는 거부된다', async () => {
  const ref = doc(client('owner'), 'users/owner');
  for (const data of [
    { ...profile(), extra: true },
    { ...profile(), nickName: '   ' },
    { ...profile(), colorIndex: -1 },
    { ...profile(), colorIndex: 8 },
    { ...profile(), colorIndex: '4' },
    { ...profile(), createdAt: Timestamp.fromMillis(1000) },
    { nickName: '밤산책 고양이', colorIndex: 4 },
  ]) await assertFails(setDoc(ref, data));
  const db = env.authenticatedContext('owner', { firebase: { sign_in_provider: 'password' } }).firestore();
  await assertFails(setDoc(doc(db, 'users/owner'), profile()));
});
