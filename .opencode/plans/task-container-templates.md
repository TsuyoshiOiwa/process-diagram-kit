# 実装計画: BPMN タスクを Container テンプレート方式へ切替

## 背景・決定事項

- タスク要素を class (属性集約) から **テンプレートオブジェクト (コンテナ) + 部分import** 方式に切替する
- 理由: クラスは子要素を持てないため、desc (説明文) 等リッチな中身を持たせたい要件を満たすため
- 既存図 (templates/process.d2, examples/order-process.d2, examples/component-check.d2) は全面書換え (ユーザー承認済み)
- 汎用 task class は削除し、テンプレート `task` に統一

## 検証済みの D2 挙動 (実測ベース)

| 項目 | 結果 |
|---|---|
| 部分import + ラベル上書き (`x: @f.obj` → `x: 文言` / `x.label: 文言`) | 両方動作 |
| 部分import + 子要素上書き (`x.desc: 文言`) | 動作 |
| 同一テンプレートの複数インスタンス + インスタンス間接続 | 独立して動作 |
| 部分import 内での `${bpmn.*}` vars 展開 | 動作 (lib/bpmn の spread import が前提) |
| 空 `desc` (shape: text, ラベルなし) | スペースを消費しない |
| `marker` (shape: image) の width/height | 正確に反映 (30×30) |
| marker の位置 | レイアウトエンジン依存 (下中央固定は不可) — 既知の制約として受け入れ |
| コンテナの箱サイズ | 子要素 + エンジンのパディングで自動決定 (~185×156 実測) — 既知の制約として受け入れ |
| CJK ラベル | 自動折返しなし (`<br/>` で手動改行が必要) |
| **未確定** 部分import時の icon 相対パス解決基準 | stdin 検証では import 先基準だった。実ファイルでは spread 時に宣言ファイル基準の実績あり → Step 0 で実検証 |

## 実装手順

### Step 0: アイコンパス検証ゲート (最初に実施)

1. Step 1 の task.d2 を書いた後、/tmp/opencode に実ファイルから絶対import するテスト d2 を作成しコンパイル
2. SVG に `data:image/svg` が埋め込まれるか確認
3. OK → 進行 / NG → フォールバック:
   - F1: vars に `icon-dir` を持たせテンプレートで参照 (`icon: ${bpmn.icon-dir}/task-user.svg`)
   - F2: (最終手段) ハイブリッド (class に icon を残し、テンプレートは class 適用 + desc 子要素のみ)

### Step 1: `lib/components/task.d2` 全面書換 (テンプレート 8種)

構造 (全テンプレート共通、marker は種別付きのみ):

```d2
task: {
  style: {
    fill: ${bpmn.task-fill}
    stroke: ${bpmn.task-stroke}
    stroke-width: 2
    border-radius: 6
    font-size: 12
  }
  desc: {
    shape: text
    style: { font-size: 12 }
  }
  marker: {
    shape: image
    icon: ../icons/task-user.svg
    width: ${bpmn.task-icon-size}
    height: ${bpmn.task-icon-size}
  }
}
```

- ファイルヘッダに使い方・制約をコメント記載
- ※ `width: ${bpmn.task-icon-size}` が数値フィールドで機能しない場合は 30 を直書きに変更

### Step 2: `lib/bpmn.d2` 修正

- `...@components/task` の spread import を削除 (テンプレートが図に漏れるため)
- classes 内の task 関連コメントを部分import 方式の説明に更新
- vars.bpmn: `task-width`, `task-height` を削除し、`task-icon-size: 30` を追加
- ヘッダコメントの使い方例を更新

### Step 3: 使用側 3 ファイルの書換え

新記法:

```d2
...@../lib/bpmn                                # vars 用に必須
受注確認: @../lib/components/task.task
受注確認: 受注内容確認                          # タスク名
受注確認.desc: 内容を確認して登録する            # 任意
```

- `templates/process.d2`: タスク1/タスク2 を部分import 化
- `examples/order-process.d2`: 全 task 使用箇所 (受注確認/受注登録/お断り/請求書発行/入金消込) を部分import 化。イベント/ゲートウェイ/フローは class のまま
- `examples/component-check.d2`: 8テンプレート + チェーン接続 + desc デモ (1〜2箇所)

### Step 4: 検証

- `make fmt` / `make check` / `make build`
- out/component-check.svg: アイコン 7 埋め込み、箱・desc 描画確認
- out/order-process.svg / out/process.svg: 図が成立しているか確認

### Step 5: README.md 更新

- 使い方を部分import 記法に書換
- クラス一覧を「クラス (イベント等)」と「テンプレート (タスク系)」に分離
- 制約 (marker 位置エンジン依存 / 箱サイズ自動 / CJK 折返し不可) を明記
- ディレクトリ構成の説明更新
