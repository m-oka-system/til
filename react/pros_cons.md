# なぜ React (コンポーネント化) を使うのか？ - メリットと簡単な例

React の基本的なチュートリアルを通して、コンポーネント、Props、State などの概念は理解できたけれど、「なぜわざわざ React を使う必要があるの？」「従来の JavaScript で書くのと何が違うの？」と感じているかもしれません。

ここでは、React を使うこと（特に UI を**コンポーネント**という部品に分けること）のメリットを、簡単な例を通して見ていきましょう。

## 例：シンプルな「いいね！」ボタン

Web ページによくある「いいね！」ボタンを考えてみます。このボタンは、クリックすると「いいね！」の数が増え、ボタンの見た目（例：色が変わる）も変化するとします。

### React を使わない場合 (素の JavaScript で実装)

```html
<!-- HTML 構造 -->
<div>
  <button id="like-button-1">いいね！</button>
  <span id="like-count-1">0</span>
</div>
<div>
  <button id="like-button-2">いいね！</button>
  <span id="like-count-2">0</span>
</div>
```

```javascript
// JavaScript での処理 (ボタンごとに処理を書く必要がある)

// --- ボタン1の処理 ---
let count1 = 0;
const button1 = document.getElementById("like-button-1");
const countSpan1 = document.getElementById("like-count-1");
let isLiked1 = false;

button1.addEventListener("click", () => {
  if (!isLiked1) {
    count1++;
    isLiked1 = true;
    button1.textContent = "いいね済み";
    button1.style.backgroundColor = "lightblue"; // 見た目を変更
  } else {
    count1--; // もう一度クリックしたら解除する処理（例）
    isLiked1 = false;
    button1.textContent = "いいね！";
    button1.style.backgroundColor = ""; // 元に戻す
  }
  countSpan1.textContent = count1; // カウント表示を更新
});

// --- ボタン2の処理 ---
let count2 = 0;
const button2 = document.getElementById("like-button-2");
const countSpan2 = document.getElementById("like-count-2");
let isLiked2 = false;

button2.addEventListener("click", () => {
  // ... ボタン1とほぼ同じ処理を再度書く ...
  if (!isLiked2) {
    count2++;
    isLiked2 = true;
    button2.textContent = "いいね済み";
    button2.style.backgroundColor = "lightblue";
  } else {
    count2--;
    isLiked2 = false;
    button2.textContent = "いいね！";
    button2.style.backgroundColor = "";
  }
  countSpan2.textContent = count2;
});

// ... もしボタンが100個あったら？ ...
```

**問題点:**

- **繰り返しが多い:** ボタンが増えるたびに、ほぼ同じ HTML 構造と JavaScript のロジック（状態管理、DOM 操作）を繰り返し書く必要があります。
- **修正が大変:** ボタンのデザインや機能を変更したい場合、すべてのボタンの処理を修正する必要があります。間違いが発生しやすく、手間がかかります。
- **コードが複雑化:** ボタンが増えたり、機能が複雑になったりすると、どの JavaScript コードがどの HTML 要素に対応しているのか追跡するのが難しくなります。

### React を使う場合 (コンポーネント化)

まず、「いいね！」ボタンの機能と見た目を一つの部品（コンポーネント）として定義します。

```javascript
// src/LikeButton.js (いいねボタンコンポーネント)
import React, { useState } from "react";

function LikeButton() {
  // State でいいねの数と状態を管理
  const [count, setCount] = useState(0);
  const [isLiked, setIsLiked] = useState(false);

  // クリックされたときの処理
  const handleClick = () => {
    if (!isLiked) {
      setCount(count + 1);
      setIsLiked(true);
    } else {
      setCount(count - 1); // 例: 解除処理
      setIsLiked(false);
    }
  };

  // コンポーネントが返す見た目 (JSX)
  return (
    <div>
      <button
        onClick={handleClick}
        style={{ backgroundColor: isLiked ? "lightblue" : "" }} // State に応じてスタイル変更
      >
        {isLiked ? "いいね済み" : "いいね！"} {/* State に応じてテキスト変更 */}
      </button>
      <span>{count}</span> {/* State を表示 */}
    </div>
  );
}

export default LikeButton;
```

そして、この `LikeButton` コンポーネントを使いたい場所で呼び出すだけです。

```javascript
// src/App.js (例: アプリケーション本体)
import React from "react";
import LikeButton from "./LikeButton"; // 作成したコンポーネントをインポート

function App() {
  return (
    <div>
      <h1>記事1</h1>
      <LikeButton /> {/* コンポーネントを呼び出す */}
      <h1>記事2</h1>
      <LikeButton /> {/* 何度でも再利用できる */}
      <h1>記事3</h1>
      <LikeButton />
    </div>
  );
}

export default App;
```

**React (コンポーネント化) のメリット:**

1.  **再利用性 (Reusability):**

    - 一度 `LikeButton` コンポーネントを作れば、必要な場所で `<LikeButton />` と書くだけで何度でも使い回せます。同じコードを繰り返し書く必要がありません。

2.  **保守性 (Maintainability):**

    - 「いいね！」ボタンの機能やデザインを変更したい場合、`LikeButton.js` ファイル**だけ**を修正すれば、すべての「いいね！」ボタンにその変更が反映されます。修正箇所が明確で、バグの混入を防ぎやすくなります。

3.  **コードの見通し (Readability / Declarative UI):**

    - `LikeButton.js` を見れば、その部品がどのような状態 (`count`, `isLiked`) を持ち、どのような見た目 (JSX) になるのか、そしてクリック時に何が起こる (`handleClick`) のかがまとまっています。
    - `App.js` では、 `<LikeButton />` と書くだけで「ここにいいねボタンが表示される」ということが**宣言的**に分かり、詳細な DOM 操作の命令を書く必要がありません。

4.  **状態管理の容易さ:**
    - 各 `LikeButton` コンポーネントは、自分自身の「いいね！」の数 (`count`) と状態 (`isLiked`) を内部の `useState` で独立して管理します。他のボタンの状態と混ざることがなく、状態管理がシンプルになります。

## React のデメリット（考慮点）

もちろん、React にもデメリットや学習が必要な点があります。

- **学習コスト:** コンポーネント、Props、State、JSX、フックなどの React 独自の概念を学ぶ必要があります。
- **環境構築:** Node.js や npm の知識、Create React App や Vite などのツールの使い方に慣れる必要があります（ただし、ツールが多くの手間を省いてくれます）。
- **複雑さ:** 非常にシンプルな Web ページ（数個の静的な要素だけ）の場合、React を導入するのはかえって複雑になる（過剰になる）こともあります。

## まとめ：どんな場合に React が有効か？

React（コンポーネント化）は、特に以下のような場合に大きなメリットを発揮します。

- **繰り返し使われる UI 部品が多い** アプリケーション（ボタン、リストアイテム、フォーム要素など）
- ユーザーの操作によって **動的に表示が変わる部分が多い** アプリケーション
- 複数人で開発したり、**長期的にメンテナンス**していく必要があるアプリケーション
- **複雑な状態管理**が必要なアプリケーション

最初は少し難しく感じるかもしれませんが、React のコンポーネントベースのアプローチに慣れると、複雑な UI を持つアプリケーションをより効率的に、そして保守しやすく開発できるようになります。
