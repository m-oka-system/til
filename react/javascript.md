**目次**

- [変数](#変数)
- [テンプレート文字列](#テンプレート文字列)
- [分割代入](#分割代入)
- [スプレッド構文](#スプレッド構文)
- [関数](#関数)

---

# 変数

JavaScript でデータを一時的に保存しておくために「変数」を使います。Python と同様に、変数を使う前に宣言が必要です。モダンな JavaScript (ES6 以降) では、変数を宣言するために主に `let` と `const` というキーワードを使います。

## 変数の宣言: `let` と `const`

### `let`

- **再代入可能な** 変数を宣言するために使います。
- 一度宣言した後、その変数に別の値を代入し直すことができます。
- 変数の値が後で変わる可能性がある場合に使います。

```javascript
// 'message' という変数を let で宣言し、初期値として "こんにちは" を代入
let message = "こんにちは";
console.log(message); // 出力: こんにちは

// message 変数に別の値を再代入
message = "さようなら";
console.log(message); // 出力: さようなら

// 初期値なしで宣言することも可能 (ただし、後で値を代入する必要がある)
let score;
score = 100;
console.log(score); // 出力: 100
```

### `const`

- **再代入不可能な** 変数（定数:constant）を宣言するために使います。
- `const` で宣言された変数には、**一度値を代入したら、その後別の値を再代入することはできません**。
- **重要:** `const` は「変数の**参照**（どの値を指しているか）が固定される」という意味です。もし変数がオブジェクトや配列の場合、その**中身（プロパティや要素）を変更することは可能**です。変数自体を別のオブジェクトや配列で上書きできない、ということです。
- 宣言時に必ず初期値を代入する必要があります。

```javascript
// 'appName' という定数を const で宣言し、初期値を代入
const appName = "すごいアプリ";
console.log(appName); // 出力: すごいアプリ

// appName に再代入しようとするとエラーになる
// appName = "普通のアプリ"; // TypeError: Assignment to constant variable.

// const で宣言したオブジェクト
const user = {
  name: "山田",
  age: 30,
};
console.log(user.name); // 出力: 山田

// オブジェクトの中身 (プロパティ) は変更可能
user.age = 31;
console.log(user.age); // 出力: 31

// オブジェクト自体を別のオブジェクトで上書きしようとするとエラー
// user = { name: "佐藤", age: 40 }; // TypeError: Assignment to constant variable.

// const で宣言した配列
const colors = ["赤", "青"];
console.log(colors[0]); // 出力: 赤

// 配列の中身 (要素) は変更可能
colors.push("緑"); // 末尾に要素を追加
console.log(colors); // 出力: ["赤", "青", "緑"]

// 配列自体を別の配列で上書きしようとするとエラー
// colors = ["白", "黒"]; // TypeError: Assignment to constant variable.
```

### `let` と `const` の使い分け

- **基本的には `const` を使う:** まずは `const` で変数を宣言することを考えましょう。これにより、意図せずに変数の値が変更されることを防ぎ、コードの安全性が高まります。
- **値の再代入が必要な場合のみ `let` を使う:** ループカウンターや、後で状態が変化することが明確な変数など、再代入が必要な場合に限り `let` を使います。

**なぜ `var` を使わないのか？**

古い JavaScript コードでは `var` というキーワードも変数宣言に使われていましたが、`var` には意図しない動作（スコープの問題や巻き上げなど）を引き起こしやすい特性があるため、**モダンな JavaScript 開発では `let` と `const` を使うことが強く推奨されます。**

# テンプレート文字列

JavaScript (ES6 以降) では、文字列をより便利に扱うための「テンプレート文字列」という機能が導入されました。これはバッククォート (`) で囲まれた文字列です。

Python の f-string (`f"..."`) に非常に似ており、同様のメリットがあります。

## テンプレート文字列の基本構文

```javascript
const name = "鈴木";
const age = 25;

// 従来の文字列結合 (+)
const message1 = "私の名前は" + name + "です。" + age + "歳です。";
console.log(message1); // 出力: 私の名前は鈴木です。25歳です。

// テンプレート文字列
const message2 = `私の名前は${name}です。${age}歳です。`;
console.log(message2); // 出力: 私の名前は鈴木です。25歳です。
```

## テンプレート文字列のメリット

1.  **変数の埋め込みが簡単:**

    - 文字列の中に変数や式を埋め込むには、`${変数名や式}` という形式を使います。
    - 従来の `+` 演算子で文字列を結合する方法よりも、コードがずっと読みやすくなります。
    - Python の f-string で `{変数名}` と書くのに似ていますね。

    ```javascript
    const item = "リンゴ";
    const price = 150;
    const taxRate = 1.1;

    const invoice = `商品: ${item}, 価格: ${price}円, 税込価格: ${
      price * taxRate
    }円`;
    console.log(invoice); // 出力: 商品: リンゴ, 価格: 150円, 税込価格: 165円
    ```

2.  **改行がそのまま反映される:**

    - テンプレート文字列の中では、改行がそのまま文字列の改行として扱われます。
    - 従来の文字列で改行を入れるには `\n` という特殊文字を使う必要がありましたが、テンプレート文字列ではその必要がありません。

    ```javascript
    // 従来の文字列
    const poem1 = "これは一行目です。\nこれは二行目です。";
    console.log(poem1);
    /*
    出力:
    これは一行目です。
    これは二行目です。
    */

    // テンプレート文字列
    const poem2 = `これは一行目です。
    これは二行目です。`; // 見たまま改行される
    console.log(poem2);
    /*
    出力:
    これは一行目です。
    これは二行目です。
    */
    ```

## まとめ

テンプレート文字列は、JavaScript で文字列を扱う際に非常に便利です。

- バッククォート (`) で囲む。
- `${...}` を使って変数や式を簡単に埋め込める（Python の f-string に似ている）。
- 改行をそのまま記述できる。

特に、文字列と変数を組み合わせて表示する場面（ログ出力、UI のテキスト生成など）でコードの可読性を大幅に向上させることができます。React のコンポーネント内で動的なテキストを生成する際にもよく使われます。

# 分割代入

分割代入は、JavaScript (ES6 以降) で導入された便利な構文で、**配列やオブジェクトから値を取り出して、個別の変数に簡単に代入する**ことができます。コードをより簡潔にし、可読性を高めるのに役立ちます。

- 分割代入は、右辺の変数（配列やオブジェクト）から値を取り出すための便利な構文です。
- 左辺には、右辺の構造に対応したパターンを書きます。
- 配列の場合: パターンは位置に基づきます。左辺で指定した位置に対応する要素が取り出されます。
- オブジェクトの場合: パターンはプロパティ名に基づきます。左辺で指定したプロパティ名と同じ名前のプロパティの値が取り出されます。

## 1. 配列の分割代入

配列の要素を、順番に基づいて個別の変数に代入します。

```javascript
// --- 従来の書き方 ---
const numbers = [10, 20, 30];
const first = numbers[0]; // 10
const second = numbers[1]; // 20
console.log(first, second); // 出力: 10 20

// --- 分割代入を使った書き方 ---
const numbers2 = [10, 20, 30];
const [first2, second2] = numbers2; // 配列の先頭から順番に first2, second2 に代入
console.log(first2, second2); // 出力: 10 20

// 特定の要素だけを取り出すことも可能 (カンマでスキップ)
const [, , third] = numbers2;
console.log(third); // 出力: 30

// 残りの要素をまとめて配列として受け取る (...rest パターン)
const numbers3 = [10, 20, 30, 40, 50];
const [first3, second3, ...rest] = numbers3;
console.log(first3); // 出力: 10
console.log(second3); // 出力: 20
console.log(rest); // 出力: [30, 40, 50] (残りの要素が新しい配列になる)
```

**Python との比較:** Python のタプルやリストのアンパッキング (`a, b = [1, 2]`) と非常に似ています。

**React での利用例 (`useState`):**

React の `useState` フックは、状態変数とその更新関数のペアを**配列**として返します。これを分割代入で受け取るのが一般的です。

```javascript
import React, { useState } from "react";

function Counter() {
  // useState(0) は [現在の値(0), 更新関数] という配列を返す
  // それを分割代入で count と setCount に代入している
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>カウント: {count}</p>
      <button onClick={() => setCount(count + 1)}>増やす</button>
    </div>
  );
}
```

もし分割代入を使わないと、以下のようになります。

```javascript
// 分割代入を使わない場合 (冗長になる)
const stateAndSetter = useState(0);
const count = stateAndSetter[0]; // 配列の0番目を取得
const setCount = stateAndSetter[1]; // 配列の1番目を取得
```

分割代入を使うことで、コードがはるかに簡潔になりますね。

## 2. オブジェクトの分割代入

オブジェクトのプロパティを、**プロパティ名に基づいて**個別の変数に代入します。配列と違い、**順番は関係ありません**。

```javascript
// --- 従来の書き方 ---
const user = {
  id: 1,
  name: "田中",
  age: 28,
  isAdmin: false,
};
const userName = user.name; // "田中"
const userAge = user.age; // 28
console.log(userName, userAge); // 出力: 田中 28

// --- 分割代入を使った書き方 ---
const user2 = {
  id: 1,
  name: "田中",
  age: 28,
  isAdmin: false,
};
// オブジェクトのプロパティ名と同じ名前の変数に値が代入される
const { name, age } = user2;
console.log(name); // 出力: 田中 (user2.name と同じ)
console.log(age); // 出力: 28 (user2.age と同じ)

// 違う変数名を使いたい場合 (リネーム)
const { name: personName, age: personAge } = user2;
console.log(personName); // 出力: 田中
console.log(personAge); // 出力: 28

// デフォルト値を設定する (プロパティが存在しない場合に使われる)
const { name: userName3, country = "日本" } = user2;
console.log(userName3); // 出力: 田中
console.log(country); // 出力: 日本 (user2 に country プロパティはないが、デフォルト値が使われる)

// 残りのプロパティをまとめてオブジェクトとして受け取る (...rest パターン)
const { id, ...otherInfo } = user2;
console.log(id); // 出力: 1
console.log(otherInfo); // 出力: { name: "田中", age: 28, isAdmin: false }
```

**Python との比較:** Python で辞書から値を取り出す場合、通常は `name = user['name']` のようにキーを指定しますが、JavaScript のオブジェクト分割代入はより宣言的に、複数のプロパティを一度に変数値として取り出せます。

**React での利用例 (Props):**

React コンポーネントが親から受け取る `props` はオブジェクトです。分割代入を使うと、必要なプロパティを簡潔に取り出すことができます。

```javascript
// --- 分割代入を使わない場合 ---
function UserProfile(props) {
  return (
    <div>
      <h2>{props.name}</h2>
      <p>年齢: {props.age}</p>
    </div>
  );
}

// --- 分割代入を関数の引数部分で使う場合 (よく使われる) ---
function UserProfile2({ name, age }) {
  // 引数 props を受け取る代わりに、直接プロパティを分割代入
  return (
    <div>
      <h2>{name}</h2>
      <p>年齢: {age}</p>
    </div>
  );
}

// 使用例
<UserProfile2 name="佐藤" age={35} />;
```

関数の引数部分で直接分割代入を使うことで、`props.name` のように毎回 `props.` と書く手間が省け、コードがすっきりします。

## まとめ

分割代入は、配列やオブジェクトから必要なデータを効率的に取り出し、変数に代入するための強力な構文です。

- **配列の場合:** `const [a, b] = array;` (順番が重要)
- **オブジェクトの場合:** `const { prop1, prop2 } = object;` (プロパティ名が重要)
- リネーム (`{ oldName: newName }`) やデフォルト値 (`{ prop = defaultValue }`)、残りの要素/プロパティの取得 (`...rest`) も可能。
- React では `useState` の結果を受け取ったり、`props` を処理したりする際によく使われ、コードを簡潔で読みやすくするのに貢献します。

# スプレッド構文

スプレッド構文 (`...`) は、JavaScript (ES6 以降で配列、ES2018 以降でオブジェクトに対応) の非常に便利な機能で、**配列やオブジェクトなどの反復可能 (iterable) な要素を展開（スプレッド）** することができます。配列やオブジェクトの結合、コピー、関数の引数渡しなど、様々な場面でコードを簡潔にするのに役立ちます。

見た目は分割代入の rest パラメーター (`...rest`) と同じ `...` ですが、**使われる文脈（場所）によって意味が変わります**。

- **分割代入の左辺 or 関数の仮引数** で使う場合: 残りの要素を集める **rest パラメーター**
- **配列リテラル (`[]`)、オブジェクトリテラル (`{}`)、関数呼び出しの引数部分** などで使う場合: 要素を展開する **スプレッド構文**

## 1. 配列でのスプレッド構文

配列の要素を個別の要素として展開します。

### 配列の結合 (Concatenation)

```javascript
const arr1 = [1, 2];
const arr2 = [3, 4];

// --- 従来の書き方 (concat メソッド) ---
const combined1 = arr1.concat(arr2);
console.log(combined1); // 出力: [1, 2, 3, 4]

// --- スプレッド構文を使った書き方 ---
const combined2 = [...arr1, ...arr2]; // arr1 と arr2 の要素を展開して新しい配列を作る
console.log(combined2); // 出力: [1, 2, 3, 4]

const combined3 = [0, ...arr1, 5, ...arr2, 6];
console.log(combined3); // 出力: [0, 1, 2, 5, 3, 4, 6]
```

### 配列のコピー (Shallow Copy)

配列の要素を新しい配列に展開することで、簡単に配列のコピー（浅いコピー）を作成できます。

```javascript
const originalArray = ["a", "b", "c"];
const copiedArray = [...originalArray];

console.log(copiedArray); // 出力: ["a", "b", "c"]

// コピーなので、元の配列を変更しても影響しない
copiedArray.push("d");
console.log(originalArray); // 出力: ["a", "b", "c"]
console.log(copiedArray); // 出力: ["a", "b", "c", "d"]

// 注意: これは浅いコピー (shallow copy) です。
// 配列の要素がオブジェクトの場合、そのオブジェクト自体はコピーされず参照がコピーされます。
const originalArrayWithObjects = [{ id: 1 }, { id: 2 }];
const copiedArrayWithObjects = [...originalArrayWithObjects];
copiedArrayWithObjects[0].id = 99;
console.log(originalArrayWithObjects[0].id); // 出力: 99 (元の配列のオブジェクトも変更されてしまう)
```

**Python との比較:** Python でリストをコピーする際の `new_list = old_list[:]` や `new_list = list(old_list)` に似ています。

### 関数の引数への展開

配列の要素を、関数の個別の引数として渡すことができます。

```javascript
function sum(x, y, z) {
  return x + y + z;
}

const numbers = [1, 2, 3];

// --- 従来の書き方 (apply メソッド) ---
const result1 = sum.apply(null, numbers);
console.log(result1); // 出力: 6

// --- スプレッド構文を使った書き方 ---
const result2 = sum(...numbers); // numbers の要素 1, 2, 3 がそれぞれ x, y, z に渡される
console.log(result2); // 出力: 6
```

**Python との比較:** Python で `func(*args_list)` のようにリストの要素を関数の位置引数として展開するのに似ています。

## 2. オブジェクトでのスプレッド構文

オブジェクトのプロパティを別のオブジェクトに展開します。

### オブジェクトのマージ (Merging)

複数のオブジェクトのプロパティを結合して、新しいオブジェクトを作成できます。同じプロパティ名がある場合、**後から展開されたオブジェクトのプロパティで上書き**されます。

```javascript
const obj1 = { a: 1, b: 2 };
const obj2 = { b: 3, c: 4 };

// --- 従来の書き方 (Object.assign) ---
const merged1 = Object.assign({}, obj1, obj2);
console.log(merged1); // 出力: { a: 1, b: 3, c: 4 } (obj2.b が obj1.b を上書き)

// --- スプレッド構文を使った書き方 ---
const merged2 = { ...obj1, ...obj2 }; // obj1 のプロパティを展開し、次に obj2 のプロパティを展開
console.log(merged2); // 出力: { a: 1, b: 3, c: 4 } (同様に obj2.b が優先)

const merged3 = { ...obj2, ...obj1 }; // 順番を変えると結果も変わる
console.log(merged3); // 出力: { b: 2, c: 4, a: 1 } (obj1.b が優先)

const merged4 = { x: 0, ...obj1, y: 5, ...obj2 };
console.log(merged4); // 出力: { x: 0, a: 1, b: 3, y: 5, c: 4 }
```

**Python との比較:** Python 3.5 以降の辞書のマージ `merged = {**dict1, **dict2}` に似ています。

### オブジェクトのコピー (Shallow Copy)

配列と同様に、オブジェクトのコピー（浅いコピー）も簡単に作成できます。

```javascript
const originalObject = { name: "佐藤", age: 40 };
const copiedObject = { ...originalObject };

console.log(copiedObject); // 出力: { name: "佐藤", age: 40 }

// コピーなので、元のオブジェクトを変更しても影響しない (プロパティがプリミティブ値の場合)
copiedObject.age = 41;
console.log(originalObject.age); // 出力: 40
console.log(copiedObject.age); // 出力: 41

// 注意: これも浅いコピーです。ネストされたオブジェクトは参照がコピーされます。
```

## React での利用例

スプレッド構文は React 開発で頻繁に使われます。

### Props の渡し方

親コンポーネントが持つ `props` オブジェクトの一部または全部を、子コンポーネントにまとめて渡すのに便利です。

```jsx
function UserProfile(props) {
  // name, age, country などの props を受け取る
  return <div>...</div>;
}

function App() {
  const userProps = { name: "鈴木", age: 25, country: "日本" };

  // userProps オブジェクトの全プロパティを UserProfile の props として渡す
  return <UserProfile {...userProps} />;
  // これは以下とほぼ同じ意味
  // return <UserProfile name={userProps.name} age={userProps.age} country={userProps.country} />;
}
```

### State のイミュータブルな更新

React では、State (特にオブジェクトや配列) を更新する際に、元の State を直接変更せず、**新しいオブジェクトや配列を作成して置き換える**（イミュータブルな更新）ことが推奨されます。スプレッド構文は、これを簡潔に行うのに役立ちます。

```javascript
// オブジェクトの State 更新例
const [user, setUser] = useState({ name: "山田", age: 30 });

const handleAgeIncrement = () => {
  // user オブジェクトを展開し、age プロパティだけを新しい値で上書きした「新しいオブジェクト」を作成
  setUser({ ...user, age: user.age + 1 });
};

// 配列の State 更新例 (要素の追加)
const [items, setItems] = useState(["A", "B"]);

const handleAddItem = () => {
  const newItem = "C";
  // items 配列を展開し、末尾に newItem を追加した「新しい配列」を作成
  setItems([...items, newItem]);
};
```

## まとめ

スプレッド構文 (`...`) は、配列やオブジェクトの要素を展開するための強力な構文です。

- 配列やオブジェクトの結合、コピーを簡潔に記述できる。
- 関数の引数に配列要素を展開して渡せる。
- React では Props の受け渡しや、State のイミュータブルな更新で非常に役立つ。
- 分割代入の rest パラメーター (`...rest`) とは使われる文脈が異なる点に注意。

# 関数

Python の `def` 文に慣れている方向けに、React 開発でよく目にする JavaScript の関数定義の方法について、Python との違いを比較しながら説明します。

JavaScript には関数を作る方法がいくつかありますが、React では主に以下の 2 つのスタイルが使われます。

1.  `function` キーワードを使った関数宣言
2.  アロー関数式 (`=>`)

## 1. `function` キーワードを使った関数宣言

これは JavaScript の伝統的な関数の定義方法です。

**JavaScript での構文:**

```javascript
function 関数名(引数1, 引数2) {
  // 関数の処理
  return 戻り値; // return 文で値を返す
}
```

**React コンポーネントの例:**

```javascript
function App() {
  return <h1>こんにちは！</h1>;
}
```

**Python との比較:**

- **キーワード:** Python の `def` に相当するのが、JavaScript の `function` です。
- **ブロックの区切り:** Python ではインデントでコードブロック（関数の本体）を表しますが、JavaScript では波括弧 `{}` で囲みます。
- **引数:** 引数を取る場合の書き方は似ています（括弧 `()` 内に記述）。
- **戻り値:** Python と同じく `return` キーワードを使って値を返します。
- **関数名:** Python と同様に関数に名前をつけます。

**主な用途:**

- React では、`App` の例のように、コンポーネント自体を定義するためによく使われます。Python でクラスや関数を定義する感覚に近いかもしれません。

## 2. アロー関数式 (`=>`)

これは比較的新しい (ES6 で導入された) JavaScript の関数定義方法で、より短く書けることが多いです。

**JavaScript での構文:**

```javascript
// 変数に関数を代入する形で定義
const 関数名 = (引数1, 引数2) => {
  // 関数の処理
  return 戻り値;
};

// 処理が1行で、その結果を直接返す場合は {} と return を省略可能
const 関数名 = (引数1, 引数2) => 戻り値;

// 引数が1つの場合は () も省略可能
const 関数名 = (引数) => 戻り値;
```

**React のイベントハンドラーの例:**

```javascript
const increment = () => {
  setCount(count + 1);
};

// 上と同じ意味 (もし setCount が値を返すなら)
// const increment = () => setCount(count + 1);
```

**Python との比較:**

- **似ているもの:** Python の `lambda` 式に少し似ていますが、JavaScript のアロー関数は `lambda` よりもはるかに強力です。
  - Python の `lambda` は通常、単一の式しか書けませんが、JavaScript のアロー関数は `{}` を使えば複数行の処理を書けます。
  - アロー関数は `return` を明示的に書くことも、省略することもできます（1 行で値を返す場合）。
- **定義方法:** アロー関数は通常、`const` や `let` を使って変数に代入する形で定義されます。Python で `func = lambda x: x + 1` と書くのに似ていますが、JavaScript ではこの書き方が非常に一般的です。
- **`this` の挙動:** (少し高度な内容) `function` で定義された関数とアロー関数では、関数内部での `this` (自分自身を参照するようなキーワード) の扱い方が異なります。React のクラスコンポーネントでは重要でしたが、**関数コンポーネントではアロー関数を使うと `this` に関する問題を避けやすい**というメリットがあります。

**主な用途:**

- React では、コンポーネント内で使う**短い処理**、特に**イベントハンドラー** (ボタンがクリックされた時の処理など) を定義するのによく使われます。簡潔に書け、`this` の問題を回避しやすいため好まれます。
- コンポーネント自体をアロー関数で定義することも可能です (`const App = () => { ... };`)。

## まとめと使い分け

| JavaScript の書き方       | Python との比較イメージ         | React での主な使われ方                                            |
| :------------------------ | :------------------------------ | :---------------------------------------------------------------- |
| `function 関数名() {}`    | `def 関数名():` に近い          | コンポーネント自体の定義 (伝統的)                                 |
| `const 関数名 = () => {}` | `関数名 = lambda: ...` より強力 | コンポーネント内の処理 (イベントハンドラー等)、コンポーネント定義 |

Python では関数定義は主に `def` を使いますが、JavaScript では `function` とアロー関数 (`=>`) の両方がよく使われます。

- **コンポーネント定義:** `function` でもアロー関数でも可能。
- **コンポーネント内のヘルパー関数/イベントハンドラー:** アロー関数が好まれる傾向。

最初は少し戸惑うかもしれませんが、どちらも「処理をまとめたもの」を作るための方法である点は同じです。それぞれの書き方と、React での使われ方の傾向を掴んでいくと良いでしょう。

## 補足: React イベントハンドラーとアロー関数

React の `onClick` などで、以下のようなアロー関数を使った書き方をよく見かけます。

```jsx
<button onClick={() => setCount(count + 1)}>クリック</button>
```

これはなぜ `onClick={setCount(count + 1)}` と直接書かないのでしょうか？

### `() => setCount(count + 1)` の文法解説

これは、**その場で新しい「無名関数」をアロー関数式で定義している** 書き方です。

1.  **`()`**: 引数リスト。引数を取らない関数であることを示します。
2.  **`=>`**: アロー記号。引数を受け取り、次の処理を実行することを示します。
3.  **`setCount(count + 1)`**: 関数の本体。`setCount` 関数を実行します。
    - この場合、`{}` がないので `setCount` の結果 (通常 `undefined`) が暗黙的に `return` されますが、重要なのは `setCount` が呼び出されることです。

全体として、これは**「呼び出された時に `setCount(count + 1)` を実行する、引数なしの新しい関数」**を定義しています。

### なぜ `onClick={setCount(count + 1)}` ではダメなのか？

- **`onClick` に渡すもの**: React のイベントハンドラー (`onClick` など) には、**「イベント発生時に実行されるべき関数 (指示書)」** を渡す必要があります。
- **`setCount(count + 1)` の意味**: これは**関数呼び出し**であり、**その場で `setCount` を実行する** という意味です。
- **問題点**: もし `onClick={setCount(count + 1)}` と書くと、コンポーネントが**描画されるたび**に `setCount` が実行されてしまいます。これにより State が更新され、再描画がトリガーされ、また `setCount` が呼ばれる... という**無限ループ**に陥る可能性があります。
- また、`setCount` は通常 `undefined` を返すため、実質的に `onClick={undefined}` となり、クリックしても意図した動作になりません。

### なぜ `onClick={() => setCount(count + 1)}` は正しいのか？

- この場合、`onClick` に渡しているのは関数呼び出しではなく、**`() => setCount(count + 1)` という新しい関数 (指示書)** です。
- この関数は定義されただけで、まだ実行されていません。
- React はこの関数をイベントハンドラーとして保持し、ユーザーが**実際にボタンをクリックしたとき**に初めて実行します。
- これにより、意図したタイミングで `setCount` が実行され、State が正しく更新されます。

**たとえ話:**

- `onClick={setCount(count + 1)}`: 「ボタンに『今すぐ電話！』と書かれたメモを貼る」 → 貼った瞬間に電話。
- `onClick={() => setCount(count + 1)}`: 「ボタンに『クリックされたら電話して』と書かれた指示書を貼る」 → クリックされるまで電話しない。

このように、イベントハンドラーには**実行する処理そのものではなく、その処理を後で実行するための関数を渡す**必要があるため、アロー関数 `() => ...` でラップする（包む）ことが一般的なのです。
