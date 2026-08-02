# Lab 08: 既存 PR をスタック化する

所要 30 分 | 使うコマンド: `link` / `init`（adopt）/ Web UI の変換バナー

---

## ゴール

「すでに手作業でブランチを積んでいる」既存の PR 群を、スタックに移行できるようになる。
チーム導入時に必ず通る道。

## 開始状態

[Lab 07](lab07-merge.md) 完了。スタックが空で、`main` に全機能がマージ済み。

```bash
# この時点ではスタックが無いので `gh stack trunk` は使えない
# （"You must be on a branch that is part of a stack." で失敗する）
cd "${PLAYGROUND_DIR:-$HOME/stacked-pr-playground}" && {
  git switch main && git pull
  gh stack view          # exit 2（スタックが無いのが正常）
}
```

---

## Step 1: 「昔ながらのやり方」で PR を 3 本作る

`gh stack` を**使わずに**、手動で base を積んだ PR を 3 本作ります。
これが移行元の状態です。

```bash
git switch main
git switch -c legacy/logger

cat > src/logger.js <<'EOF'
export function createLogger(prefix = 'app') {
  return {
    info: (msg) => console.log(`[${prefix}] INFO  ${msg}`),
    warn: (msg) => console.warn(`[${prefix}] WARN  ${msg}`),
    error: (msg) => console.error(`[${prefix}] ERROR ${msg}`),
  };
}
EOF

git add src/logger.js
git commit -m "feat(logger): add console logger"
git push -u origin legacy/logger
gh pr create --base main --head legacy/logger --title "feat(logger): add console logger" --body "1/3"
```

2 本目（base は `legacy/logger`）:

```bash
git switch -c legacy/metrics

cat > src/metrics.js <<'EOF'
import { createLogger } from './logger.js';

export function createMetrics(logger = createLogger('metrics')) {
  const counters = new Map();
  return {
    increment(name) {
      counters.set(name, (counters.get(name) ?? 0) + 1);
      logger.info(`${name}=${counters.get(name)}`);
    },
    snapshot: () => Object.fromEntries(counters),
  };
}
EOF

git add src/metrics.js
git commit -m "feat(metrics): add counter metrics"
git push -u origin legacy/metrics
gh pr create --base legacy/logger --head legacy/metrics --title "feat(metrics): add counter metrics" --body "2/3"
```

3 本目（base は `legacy/metrics`）:

```bash
git switch -c legacy/telemetry

cat > src/telemetry.js <<'EOF'
import { createMetrics } from './metrics.js';

export function instrument(api, metrics = createMetrics()) {
  return new Proxy(api, {
    get(target, key) {
      const handler = target[key];
      if (typeof handler !== 'function') return handler;
      return (...args) => {
        metrics.increment(String(key));
        return handler(...args);
      };
    },
  });
}
EOF

git add src/telemetry.js
git commit -m "feat(telemetry): instrument api handlers"
git push -u origin legacy/telemetry
gh pr create --base legacy/metrics --head legacy/telemetry --title "feat(telemetry): instrument api handlers" --body "3/3"
```

現状を確認します。

```bash
gh pr list --json number,headRefName,baseRefName --jq '.[] | "\(.number)\t\(.headRefName)\t→ \(.baseRefName)"'
gh stack view          # まだスタックとしては認識されていない（exit 2）
```

base は積まれていますが、**GitHub 上ではスタックとして扱われていません**。
stack map も出ませんし、`gh stack merge` の対象にもなりません。

---

## Step 2: Web UI の変換バナーを確認する

base が正しく数珠つなぎになっている PR 群には、
GitHub が「これはスタックにできます」という**推奨バナー**を表示します。

```bash
gh pr view <legacy/telemetry の PR 番号> --web
```

バナーが表示されていれば、クリックひとつでスタックに変換できます。

> [!NOTE]
> バナーは「各 PR の base が 1 つ下の PR の head と一致している」場合に出ます。
> 1 つでも base がずれているとバナーは出ません。その場合は Step 3 の CLI を使います。

---

## Step 3: `gh stack link` で CLI から変換する

Web UI を使わず CLI で変換する方法です。**ローカル追跡なしで**、GitHub 上の PR をスタックにリンクします。

```
gh stack link [flags] <stack-number | branch-or-pr> <branch-or-pr> [...]
```

| フラグ            | 意味                           |
| ----------------- | ------------------------------ |
| `--base <branch>` | スタック最下層の base ブランチ |
| `--open`          | PR を ready for review にする  |
| `--remote <name>` | 対象のリモート                 |

**下から順に**指定します。

```bash
gh stack link --base main legacy/logger legacy/metrics legacy/telemetry
```

PR 番号でも指定できます。

```bash
gh stack link --base main 6 7 8
```

確認します。

```bash
gh stack view                                   # exit 2。link はローカル追跡を作らないため正常
gh pr view <legacy/logger の PR 番号> --web     # stack map が表示される
```

> [!TIP]
>
> `link` は**ローカル追跡を作りません**。GitHub 上でリンクするだけです。
> ローカルでも `up` / `down` / `rebase` を使いたい場合は、次の Step 4 を実行してください。

---

## Step 4: ローカル追跡を作る — `init` による adopt

`gh stack init` に**既存のブランチ名**を渡すと、そのブランチがスタックに取り込まれます（adopt）。
複数まとめて渡せます。

```bash
git switch main
gh stack init --base main legacy/logger legacy/metrics legacy/telemetry
gh stack view
```

これでローカルでもスタックとして操作できます。

```bash
gh stack bottom && git branch --show-current
gh stack up     && git branch --show-current
gh stack top    && git branch --show-current
```

もう一つの方法は、リンク済みのスタックを `checkout` で取り込むことです。
**他人のスタックをレビューする際はこちらが主力**になります。

```bash
gh stack checkout <PR 番号 or URL>
```

---

## Step 5: 移行後の確認

移行が成功したかを 4 点チェックします。

```bash
# 1. スタックとして認識されている
gh stack view

# 2. base が正しく積まれている
gh pr list --json number,headRefName,baseRefName --jq '.[] | "\(.number)\t\(.headRefName)\t→ \(.baseRefName)"'

# 3. stack map が表示される
gh stack bottom && gh pr view --web

# 4. スタック操作が効く
gh stack sync
```

---

## Step 6: 移行できないケース

| ケース                                   | 対応                                                                      |
| ---------------------------------------- | ------------------------------------------------------------------------- |
| **base がずれている**                    | 該当 PR の base を手で直してから `link`。`gh pr edit <n> --base <branch>` |
| **fork からの PR が混ざっている**        | 移行不可。cross-fork stack は非対応。同一リポジトリのブランチに移す       |
| **PR が枝分かれしている**                | スタックは線形のみ。順序を決めて直列化するか、別スタックに分ける          |
| **すでにマージ済みの PR が混ざっている** | マージ済みを除いた残りでスタックを作る                                    |
| **PR がない（ブランチだけ）**            | `gh stack init` で adopt してから `gh stack submit` で PR を作る          |

---

## Step 7: 後片付け

このあとの [Lab 09](lab09-ci-protection.md) で使うので、**このスタックは残しておきます**。

不要になったら:

```bash
gh stack unstack               # スタックのリンクを解除（PR は残る）
```

---

## 確認ポイント

- [ ] 手作業で積んだ PR 群を作れた
- [ ] Web UI の変換バナーの場所と表示条件が分かった
- [ ] `gh stack link` で GitHub 上のスタックにできた
- [ ] `gh stack init <既存ブランチ...>` でローカル追跡を作れた
- [ ] `link` と `init` の役割の違いを説明できる

---

## つまずきポイント

| 症状                                           | 原因と対処                                                                     |
| ---------------------------------------------- | ------------------------------------------------------------------------------ |
| `link` が失敗する                              | 指定順が逆（上から並べた）。**下から順に**指定する                             |
| 変換バナーが出ない                             | base の連鎖が切れている。`gh pr list` で base を確認して修正                   |
| `init` で「ブランチが見つからない」            | ローカルに fetch されていない。`git fetch origin` してから再実行               |
| `link` 後もローカルで `up` / `down` が効かない | `link` はローカル追跡を作らない。`gh stack init` か `gh stack checkout` を実行 |
| 移行後の PR の差分が想定と違う                 | base のずれ。`gh stack sync` でリベースし直す                                  |

---

## 振り返り課題

1. `gh stack link` と `gh stack init` の違いを説明せよ。
2. base が数珠つなぎになっていない 3 本の PR をスタック化したい。手順は。
3. OSS に fork 経由でコントリビュートしている。スタックに移行できるか。
4. チーム 10 人が既存のブランチ運用をしている。移行時に最初に決めるべきことは何か。

<details>
<summary>解答</summary>

1. `link` は GitHub 上の PR をスタックとしてリンクするだけで、ローカル追跡を作らない。
   `init` はローカルにスタック追跡を作る（既存ブランチを渡せば adopt する）。
   両方欲しい場合は `init` してから `submit`、または `link` してから `checkout`。
2. 先に各 PR の base を `gh pr edit <n> --base <branch>` で連鎖するよう直し、
   その上で `gh stack link --base main <下> <中> <上>` を実行する。
3. できない。cross-fork stack は非対応。upstream に直接 push できるブランチが必要。
4. **層の切り方の規約**（何を 1 層にするか）と**マージ方式**。
   加えて、並べ替えに CLI が必須なので、CLI 拡張を全員に入れるか / 順序を最初に固める運用にするかを決める。

</details>

---

次は [Lab 09: ブランチ保護と CI](lab09-ci-protection.md) へ。
