import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, Timestamp, writeBatch } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-minifeed-repositories',
});

try {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const batch = writeBatch(db);
    const createdAt = Timestamp.fromMillis(Date.UTC(2026, 0, 1));
    const author = { authorId: 'fixture-author', nickName: '테스트 펭귄', colorIndex: 0 };

    for (let number = 1; number <= 45; number += 1) {
      const id = 'fixture-' + String(number).padStart(2, '0');
      batch.set(doc(db, 'posts', id), {
        ...author,
        body: '게시글 ' + number,
        createdAt,
        likeCount: 0,
        commentCount: number === 45 ? 2 : 0,
      });
    }

    for (const [id, body, minute] of [
      ['late', '나중에 쓴 댓글', 2],
      ['early', '먼저 쓴 댓글', 1],
    ]) {
      batch.set(doc(db, 'posts', 'fixture-45', 'comments', id), {
        ...author,
        body,
        createdAt: Timestamp.fromMillis(createdAt.toMillis() + minute * 60000),
      });
    }

    await batch.commit();
  });
} finally {
  await env.cleanup();
}
