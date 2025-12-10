# Firebase Cloud Functions 설정 가이드 (사용자 자동 삭제)

관리자 페이지에서 사용자를 삭제할 때, 즉시 삭제하지 않고 **7일 후 자동 삭제**되도록 설정하려면 Firebase Cloud Functions가 필요합니다.
앱 내 코드는 사용자를 '삭제 예정' 상태로 표시하고 로그인을 차단하는 역할만 수행하며, 실제 데이터 삭제는 아래 Cloud Function이 담당합니다.

## 1. Firebase CLI 설치 및 초기화

프로젝트 루트가 아닌 별도의 폴더(또는 프로젝트 내 `functions` 폴더)에서 진행하세요.

```bash
npm install -g firebase-tools
firebase login
firebase init functions
```

## 2. `functions/index.js` 작성

생성된 `functions/index.js` 파일에 아래 코드를 작성합니다. 이 코드는 매일 자정에 실행되어 삭제 예정일(`deletionDueAt`)이 지난 사용자를 찾아 영구 삭제합니다.

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deleteScheduledUsers = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
  const db = admin.firestore();
  const auth = admin.auth();
  const now = admin.firestore.Timestamp.now();

  // 1. 삭제 예정일(deletionDueAt)이 지난 사용자 조회
  const snapshot = await db.collection("users")
    .where("status", "==", "scheduled_for_deletion")
    .where("deletionDueAt", "<=", now)
    .get();

  if (snapshot.empty) {
    console.log("삭제할 사용자가 없습니다.");
    return null;
  }

  const batch = db.batch();
  const deletePromises = [];

  snapshot.docs.forEach((doc) => {
    const userId = doc.id;

    // 2. Firebase Auth 계정 삭제
    const deleteAuth = auth.deleteUser(userId)
      .then(() => console.log(`Auth 계정 삭제 성공: ${userId}`))
      .catch((error) => console.error(`Auth 계정 삭제 실패: ${userId}`, error));
    deletePromises.push(deleteAuth);

    // 3. 사용자 작성 게시물 삭제 (선택 사항: 컬렉션 구조에 따라 다름)
    // 예: 'posts' 컬렉션에서 해당 사용자의 게시물 삭제
    const deletePosts = db.collection("posts").where("uid", "==", userId).get()
      .then((postSnapshot) => {
        const postBatch = db.batch();
        postSnapshot.docs.forEach((postDoc) => {
          postBatch.delete(postDoc.ref);
        });
        return postBatch.commit();
      });
    deletePromises.push(deletePosts);

    // 4. 사용자 문서 삭제
    batch.delete(doc.ref);
  });

  // 모든 작업 실행
  await Promise.all(deletePromises);
  await batch.commit();

  console.log(`${snapshot.size}명의 사용자와 관련 데이터를 삭제했습니다.`);
  return null;
});
```

## 3. 배포

작성한 함수를 Firebase에 배포합니다.

```bash
firebase deploy --only functions
```

## 작동 방식

1.  **관리자 앱**: `deleteUser` 함수가 호출되면 사용자의 `status`를 `scheduled_for_deletion`으로 변경하고, `deletionDueAt`을 7일 뒤로 설정합니다. 또한 `isBanned`를 `true`로 설정하여 즉시 로그인을 차단합니다.
2.  **Cloud Functions**: 매일 한 번씩 실행되어 `deletionDueAt`이 지난 사용자를 찾습니다.
3.  **자동 삭제**: 해당 사용자의 Firebase Auth 계정, Firestore 문서, 그리고 작성한 게시물을 영구 삭제합니다.
