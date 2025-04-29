# React 基本チュートリアル

このチュートリアルでは、React の基本的な概念と機能を学びます。環境構築がまだの方は、先に `install.md` を参照して準備をしてください。

## 1. 前提知識

このチュートリアルを進めるにあたり、以下の知識があるとスムーズです。

- **HTML**: Web ページの骨組みを作るマークアップ言語。
- **CSS**: Web ページの見た目を装飾するスタイルシート言語。
- **JavaScript**: Web ページに動きをつけるプログラミング言語（基本的な文法、変数、関数、オブジェクト、配列、アロー関数など）。

## 2. プロジェクトの構造を確認しよう

`create-react-app` で作成したプロジェクト (`my-app` など) の中身を見てみましょう。重要なファイルやフォルダは以下の通りです。

- `my-app/`
  - `node_modules/`: プロジェクトが利用するライブラリ（パッケージ）が格納されるフォルダ（直接編集することはありません）。
  - `public/`: 静的なファイル（HTML ファイル、画像など）を置くフォルダ。
    - `index.html`: ブラウザが最初に読み込む HTML ファイル。React はこのファイルにアプリケーションを描画します。
  - `src/`: **主に開発で編集するソースコード** を置くフォルダ。
    - `index.js`: JavaScript のエントリーポイント（起点）。`public/index.html` と React アプリケーションを繋ぎます。
    - `App.js`: アプリケーションのメインとなるコンポーネント。
    - `App.css`: `App.js` コンポーネント用の CSS ファイル。
  - `package.json`: プロジェクトの情報（名前、バージョン、依存ライブラリなど）が書かれた設定ファイル。

## 3. コンポーネントと JSX

React アプリケーションは、**コンポーネント (Component)** という小さな部品を組み合わせて作られます。コンポーネントは、UI（見た目）の一部をカプセル化したもので、再利用可能です。

`src/App.js` を見てみましょう。これが `App` という名前の関数コンポーネントです。

```javascript
// src/App.js (初期状態の例)
import React from "react"; // Reactライブラリを読み込む
import logo from "./logo.svg"; // 画像ファイルを読み込む
import "./App.css"; // CSSファイルを読み込む

// App という名前の関数コンポーネントを定義
function App() {
  // この関数が返すものが、画面に表示される内容 (HTMLのようなもの)
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

// 他のファイルでこの App コンポーネントを使えるようにエクスポート
export default App;
```

注目すべきは `return` の中の、HTML に似た記述です。これは **JSX (JavaScript XML)** と呼ばれる記法で、JavaScript の中に UI の構造を宣言的に書くことができます。

- **ポイント**: JSX は HTML と似ていますが、完全に同じではありません。
  - `class` 属性の代わりに `className` を使います（`class` は JavaScript の予約語のため）。
  - JavaScript の式（変数、関数の結果など）を埋め込む場合は `{}` を使います (例: `{logo}`）。

試しに `src/App.js` の `<p>` タグの中身を書き換えて保存してみましょう。開発サーバーが動いていれば、ブラウザの表示が自動で更新されるはずです。

### 質問

import logo from './logo.svg'; の一行は変数を定義するための構文ですか？
通常、Javascript の変数定義は `const key1 = value1` のような形ではありませんか？

import 文は、他のモジュールを取り込むための構文であると理解しています。
`{ logo }` という記法は、変数を参照していることは直感的にわかりますが、その宣言方法がわかりづらいです。

### 回答

おっしゃる通り、`import logo from './logo.svg';` は、厳密には `const logo = ...` のような JavaScript の**変数宣言構文そのものではありません**。ユーザーさんの理解されている通り、`import` は**他のモジュール（ファイル）からエクスポートされた機能や値を取り込むための構文**です。

では、なぜこれが変数 `logo` を使えるようにしているのか、少し詳しく見ていきましょう。

1.  **モジュールのエクスポートとインポート**:

    - JavaScript (ES6 以降) では、ファイル（モジュール）ごとに機能を部品化し、必要なものだけを外部に公開（**エクスポート**）できます。
    - 別のファイルでは、公開された機能や値を**インポート**して利用します。

2.  **`import logo from './logo.svg';` の意味**:

    - この構文は、`./logo.svg` というモジュール（この場合は Webpack などのツールによって特別に処理される SVG ファイル）が **「デフォルト」としてエクスポートしている値** をインポートし、それを `logo` という名前で**このファイル（`App.js`）のスコープ内で使えるようにする**、という意味になります。
    - 結果的に、`App.js` の中では `logo` という名前で、インポートされた値（`logo.svg` へのパスなど）を参照できるようになります。あたかも `const logo = (./logo.svg からインポートされた値);` のように宣言されたかのように振る舞いますが、構文としては `import` を使っています。

3.  **`const` との違い**:
    - `const logo = ...;` は、その場で値を計算したり、リテラル（文字列や数値など）を使って変数を**宣言し初期化する**ための構文です。
    - `import logo from ...;` は、別のモジュールから提供される値を**受け取る**ための構文です。値そのものはインポート元のモジュール（またはそれを処理するツール）によって決定されます。
    - また、`import` で作られた変数 (`logo`) は読み取り専用であり、後から `logo = "別の値";` のように再代入することはできません。これは `const` に似ていますが、`import` 固有の性質です。

**まとめ**:

`import logo from './logo.svg';` は、変数宣言の構文 (`const` など) とは異なりますが、**結果として `logo` という名前の変数を現在のスコープに導入し、インポートした値をそれに紐付ける** 役割を果たします。そのため、後続のコードで `{logo}` のようにしてその値を参照できるわけです。

`import` 文が「変数を宣言している」ように見えるのは、このようにモジュールから値を受け取って名前をつける機能を持っているためです。その宣言方法が `const` とは違う形である、と理解していただけると良いかと思います。

## 4. Props (プロパティ)

コンポーネントに外部からデータを渡したい場合があります。その際に使うのが **Props (プロパティ)** です。Props は、親コンポーネントから子コンポーネントへデータを渡すための仕組みで、読み取り専用です。

例として、挨拶メッセージを表示する `Greeting` コンポーネントを作ってみましょう。

まず、`src` フォルダに `Greeting.js` というファイルを作成します。

```javascript
// src/Greeting.js
import React from "react";

// 親コンポーネントから 'name' という props (オブジェクト) を受け取る
// コンポーネントが受け取るオブジェクトには props という名前を使うのが慣習
function Greeting(props) {
  // props.name のようにして値にアクセスできる
  return <h1>こんにちは, {props.name} さん！</h1>;
}

export default Greeting;
```

次に、`src/App.js` を編集して、この `Greeting` コンポーネントを使ってみます。

```javascript
// src/App.js (編集後)
import React from "react";
import "./App.css";
// 作成した Greeting コンポーネントをインポート
import Greeting from "./Greeting";

function App() {
  return (
    <div className="App">
      {/* Greeting コンポーネントを呼び出し、name という名前で "React" という文字列を渡す */}
      <Greeting name="React" />
      {/* 別の名前を渡すこともできる */}
      <Greeting name="あなた" />
    </div>
  );
}

export default App;
```

- **ポイント**:
  - 子コンポーネント (Greeting) は、引数 (props) でオブジェクトを受け取ります。
  - 親コンポーネント (App) は、子コンポーネントを呼び出す際に属性のような形でオブジェクトを渡します (`name="React"`)。
  - Props は読み取り専用なので、`Greeting` コンポーネント内で `props.name = "別の名前"` のように変更することはできません。

## 5. State (ステート)

Props は親から子へデータを渡す一方通行でしたが、コンポーネント自身が内部で状態（データ）を持ち、それが時間経過やユーザー操作によって変化することがあります。このような変化するデータを管理するのが **State (ステート)** です。

関数コンポーネントで State を使うには、**`useState` フック** を利用します。

- **フック (Hook) とは？**: 関数コンポーネントに State やライフサイクル機能（特定のタイミングで処理を実行する機能）を追加するための特別な関数です (`useState`, `useEffect` などがあります)。

例として、ボタンをクリックするとカウントが増えるカウンターを作ってみましょう。

`src/App.js` を以下のように編集します。

```javascript
// src/App.js (カウンターの例)
import React, { useState } from "react"; // useState フックをインポート
import "./App.css";

function App() {
  // useState フックを使って State 変数 'count' と、それを更新する関数 'setCount' を宣言
  // useState(0) の 0 は count の初期値
  const [count, setCount] = useState(0);

  // ボタンがクリックされたときに呼ばれる(引数を取らない)関数
  const increment = () => {
    // setCount を使って count の値を更新する (return しない)
    setCount(count + 1);
  };

  return (
    <div className="App">
      <h1>シンプルなカウンター</h1>
      {/* 現在のカウント数を表示 */}
      <p>カウント: {count}</p>
      {/* ボタンをクリックしたら increment 関数を実行 */}
      <button onClick={increment}>クリックして増やす</button>

      {/* ボタンをクリックしたら increment 関数を実行 */}
      <button onClick={() => setCount(count + 1)}>クリックして増やす</button>
    </div>
  );
}

export default App;
```

- **ポイント**:
  - `useState(初期値)` は、State 変数とその更新関数のペアを配列で返します (`[count, setCount]`)。
  - State を更新するには、直接 State 変数 (`count`) を変更するのではなく、必ず更新関数 (`setCount`) を使います。
  - 更新関数が呼ばれると、React はコンポーネントを再レンダリング（再描画）し、画面の表示を更新します。

## 6. イベント処理

ユーザーの操作（クリック、入力、マウスオーバーなど）に反応するには、イベントハンドラーを使います。

上記のカウンターの例では、`button` 要素に `onClick` という Props を渡しています。これがクリックイベントに対するイベントハンドラーです。

```javascript
<button onClick={increment}>クリックして増やす</button>
```

- **ポイント**:
  - JSX でのイベント名はキャメルケース (`onClick`, `onChange`, `onSubmit` など) になります。
  - イベントハンドラーには、実行したい関数を `{}` で囲んで渡します。

## 7. リストとキー

データの配列を元に、リスト表示をしたいことがよくあります。JavaScript の `map()` メソッドを使うと、配列の各要素を JSX 要素に変換できます。

リスト表示を行う際には、各リストアイテムに **`key`** という特別な Props を指定する必要があります。`key` は、リストのどの項目が変更、追加、削除されたのかを React が識別するのに役立ちます。

例として、果物のリストを表示してみましょう。

`src/App.js` を編集します。

```javascript
// src/App.js (リスト表示の例)
import React from "react";
import "./App.css";

function App() {
  // 表示したい果物の配列
  const fruits = [
    { id: 1, name: "りんご" },
    { id: 2, name: "ばなな" },
    { id: 3, name: "みかん" },
  ];

  return (
    <div className="App">
      <h1>果物リスト</h1>
      <ul>
        {/* fruits 配列を map で処理して li 要素のリストを生成 */}
        {fruits.map((fruit) => (
          // 各 li 要素に、ユニークな key を指定する (ここでは fruit.id を使用)
          <li key={fruit.id}>{fruit.name}</li>
        ))}
      </ul>
    </div>
  );
}

export default App;
```

- **ポイント**:
  - 配列の `map()` メソッドを使って、配列の要素一つひとつを JSX 要素 (`<li>`) に変換します。
  - `map()` で生成される各要素には、兄弟要素間でユニーク（一意）な `key` Props を必ず指定します。
  - `key` には、データが持つユニークな ID を使うのが一般的です。配列のインデックスを `key` に使うこともできますが、リストの順序が変わったり、要素が追加/削除されたりする場合に問題が起きる可能性があるため、安定した ID がある場合はそちらを使いましょう。

## 8. 条件付きレンダリング

特定の条件に基づいて、コンポーネントの一部を表示したり非表示にしたりしたい場合があります。これを **条件付きレンダリング** と呼びます。

JavaScript の `if` 文や三項演算子 (`条件 ? 真の場合 : 偽の場合`)、論理 AND 演算子 (`&&`) などを使って実現できます。

例として、ログイン状態によって表示するメッセージを変えてみましょう。

`src/App.js` を編集します。

```javascript
// src/App.js (条件付きレンダリングの例)
import React, { useState } from "react";
import "./App.css";

// ログイン状態に応じてメッセージを表示するコンポーネント
function UserGreeting(props) {
  // isLogin が true なら
  if (props.isLogin) {
    return <h1>ようこそ！</h1>;
  }
  // isLogin が false なら
  return <h1>ログインしてください。</h1>;
}

function App() {
  // ログイン状態を管理する State (初期値は false)
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  return (
    <div className="App">
      {/* UserGreeting コンポーネントにログイン状態を渡す */}
      <UserGreeting isLogin={isLoggedIn} />

      {/* ボタンをクリックしたらログイン状態を切り替える */}
      <button onClick={() => setIsLoggedIn(!isLoggedIn)}>
        {/* ボタンのテキストも条件によって変える (三項演算子の例) */}
        {isLoggedIn ? "ログアウト" : "ログイン"}
      </button>

      <hr />

      {/* 論理 AND 演算子 (&&) を使った例 */}
      {/* isLoggedIn が true の場合のみメッセージを表示 */}
      {isLoggedIn && <p>ログイン中です。追加情報はこちら。</p>}
    </div>
  );
}

export default App;
```

- **ポイント**:
  - `if` 文: コンポーネントの `return` 前に条件分岐を書く場合に便利です。
  - 三項演算子 (`条件 ? A : B`): JSX の中で簡単な条件分岐を埋め込むのに適しています。
  - 論理 AND (`条件 && 式`): 条件が `true` の場合にのみ `式` の部分を表示したい場合に簡潔に書けます。

## 9. まとめ

このチュートリアルでは、React の基本的な概念を学びました。

- **コンポーネント**: UI を構成する再利用可能な部品。
- **JSX**: JavaScript 内で UI 構造を記述するための記法。
- **Props**: 親から子へデータを渡す仕組み（読み取り専用）。
- **State**: コンポーネントが内部で持つ、変化するデータ (`useState` フック)。
- **イベント処理**: ユーザー操作への対応 (`onClick` など)。
- **リストとキー**: 配列データを表示する方法と `key` の重要性。
- **条件付きレンダリング**: 条件に応じた表示の切り替え。

これらは React 開発の基礎となります。さらに深く学ぶには、公式ドキュメントを読んだり、他のチュートリアルを試したり、実際に何かアプリケーションを作ってみるのが良いでしょう。

[React 公式ドキュメント (日本語)](https://ja.react.dev/)
