import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, serverTimestamp, setDoc, Timestamp, writeBatch,
} from 'firebase/firestore';

let env;
const profile = { nickName: '밤산책 고양이', colorIndex: 4 };
const postPath = 'posts/delete-case';
const markerPath = 'deletedPosts/delete-case';
const children = ['comments', 'likes', 'reports'];

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-minifeed-auth',
    firestore: { rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/writer'), { ...profile, createdAt: Timestamp.now() });
    batch.set(doc(db, postPath), postData(Timestamp.now()));
    for (const child of children) batch.set(doc(db, postPath, child, 'reader'), { authorId: 'reader' });
    await batch.commit();
  });
});

function postData(createdAt) {
  return { ...profile, authorId: 'writer', body: '삭제 확인', likeCount: 0, commentCount: 0, createdAt };
}

function deletePost(db) {
  const batch = writeBatch(db);
  batch.delete(doc(db, postPath));
  batch.set(doc(db, markerPath), { deletedAt: serverTimestamp() });
  return batch.commit();
}

test('작성자가 삭제하면 두 사용자의 피드·상세에서 사라지고 하위 기록은 접근할 수 없다', async () => {
  // given
  const owner = env.authenticatedContext('writer').firestore();
  const reader = env.authenticatedContext('reader').firestore();
  assert.equal((await getDoc(doc(reader, postPath))).exists(), true);
  assert.equal((await getDocs(collection(reader, postPath, 'comments'))).size, 1);

  // when
  await assertSucceeds(deletePost(owner));

  // then
  for (const db of [reader, owner]) {
    assert.equal((await getDoc(doc(db, postPath))).exists(), false);
    assert.equal((await getDocs(collection(db, 'posts'))).empty, true);
    for (const child of children) {
      const records = collection(db, postPath, child);
      await assertFails(getDocs(records));
      await assertFails(getDoc(doc(records, 'reader')));
      await assertFails(setDoc(doc(records, 'new'), { authorId: 'reader' }));
    }
  }
  await assertFails(setDoc(doc(owner, postPath), postData(serverTimestamp())));
  await assertFails(deleteDoc(doc(owner, markerPath)));
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    for (const child of children) {
      assert.equal((await getDocs(collection(db, postPath, child))).size, 1);
    }
  });
});

test('타인·미인증 삭제 및 단독 삭제 기록 생성을 거부하고 원본을 보존한다', async () => {
  // given
  const owner = env.authenticatedContext('writer').firestore();
  const reader = env.authenticatedContext('reader').firestore();
  const guest = env.unauthenticatedContext().firestore();

  // when
  for (const db of [reader, guest]) await assertFails(deletePost(db));
  await assertFails(setDoc(doc(owner, markerPath), { deletedAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(owner, postPath)));

  // then
  assert.equal((await getDoc(doc(reader, postPath))).exists(), true);
  await assertFails(getDoc(doc(guest, postPath)));
});
