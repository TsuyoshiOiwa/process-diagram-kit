# d2-bpmn

D2 で BPMN 風の業務プロセス図を作成するためのテンプレート・モデル・クラス定義集。

最終成果物 (SVG 等) は本リポジトリでは管理せず、`.d2` ソースのみを管理する。

## 前提

| ツール | 用途 | インストール |
|---|---|---|
| d2 CLI (v0.8+) | コンパイル・整形・検証 | `curl -fsSL https://d2lang.com/install.sh \| sh -s --` |
| VS Code 拡張 `terrastruct.d2` | エディタ内プレビュー・補完 | `code --install-extension terrastruct.d2` |

## クイックスタート

```bash
make watch        # サンプルをライブプレビュー (保存で自動再描画)
                  # make watch FILE=examples/component-check.d2 のようにファイル指定も可能
                  # リモート環境では VS Code のポート転送で 39981 番を開き
                  # ローカルブラウザで http://localhost:39981 にアクセス
```

VS Code で `.d2` ファイルを開き、コマンドパレットの D2 プレビューでも確認できる。

## ディレクトリ構成

```
lib/bpmn.d2            共通ライブラリ: 色トークン (vars) + イベント等のクラス定義
lib/components/task.d2   タスクテンプレート集 (図から部分import して使う)
lib/components/container.d2   プール・レーンテンプレート集 (図から部分import して使う)
lib/components/stroke.d2   接続 (フロー) クラス集 (bpmn.d2 経由で利用可能)
lib/components/event.d2   イベント種別クラス集 (bpmn.d2 経由で利用可能)
lib/components/gateway.d2   ゲートウェイ種別クラス集 (bpmn.d2 経由で利用可能)
lib/components/data.d2   データ要素クラス集 (bpmn.d2 経由で利用可能)
lib/icons/             BPMN マーカー SVG (テンプレートのアイコンとして参照)
templates/process.d2   新規図作成用テンプレート
examples/order-process.d2   利用例 (受注処理プロセス)
examples/component-check.d2   テンプレートの動作確認用 (全要素の見た目確認)
```

## 新規図の作り方

1. `templates/process.d2` をコピーする
2. プール・レーン・要素・フローを編集する
3. `d2 fmt ファイル.d2` で整形する

## 要素定義

### タスク (テンプレート / lib/components/task.d2)

タスクは説明文 (`desc`) を持てるようコンテナのテンプレートとして定義している。
図ファイルから **部分import** して使う (クラス記法は使えない)。

```d2
承認: @../lib/components/task.user-task
承認: 承認処理              # タスク名
承認.desc: 人間が確認する処理   # 説明文 (任意, 未設定なら領域を取らない)
```

| テンプレート | BPMN 要素 | 内容物 |
|---|---|---|
| `task` | タスク | 角丸矩形 (青) のみ |
| `user-task` | ユーザータスク | + 人アイコン |
| `manual-task` | マニュアルタスク | + 手アイコン |
| `service-task` | サービスタスク | + ギアアイコン |
| `script-task` | スクリプトタスク | + スクリプトアイコン |
| `business-rule-task` | ビジネスルールタスク | + ルールアイコン |
| `send-task` | 送信タスク | + 送信アイコン |
| `receive-task` | 受信タスク | + 受信アイコン |

テンプレート適用上の制約 (D2 の仕様):

- アイコン (marker) の位置はレイアウトエンジンが決める (座標指定は不可)
- 箱のサイズは子要素とパディングから自動決定される (最小値の指定は不可)
- タスク名は自動折返ししない (長い場合は `<br/>` で改行する)

### プール / レーン (テンプレート / lib/components/container.d2)

プール・レーンもコンテナのテンプレートとして定義している。
図ファイルから **部分import** して使う (クラス記法は使えない)。
ラベルは BPMN の左ラベル帯の代用として左中央に横書き表示される。

```d2
プールA: @../lib/components/container.pool
プールA: プールA                # プール名
営業: @../lib/components/container.lane
営業: 営業                      # レーン名
```

| テンプレート | BPMN 要素 | 表現 |
|---|---|---|
| `pool` | プール | コンテナ (太枠, ラベル左中央) |
| `lane` | レーン | コンテナ (プール内, ラベル左中央) |

テンプレート適用上の制約 (D2 の仕様):

- BPMN 標準の縦書きラベル帯は D2 が縦書き非対応のため、横書き・左中央で代用する
- ラベル用の空き領域はレイアウトエンジンが保証しないため、子要素と重なる場合は図側で調整する

### その他の要素 (クラス / lib/bpmn.d2)

`要素.class: クラス名` で適用する。

| クラス | BPMN 要素 | 表現 |
|---|---|---|
| `subprocess` | サブプロセス | 破線枠の角丸矩形 |

イベントの円 (開始 / 中間 / 終了) もクラスで適用する
(種別アイコン付きの定義は後述の「イベント種別」を参照)。

### ゲートウェイ (クラス / lib/components/gateway.d2)

アイコン付きのゲートウェイ。`要素.class: クラス名` で適用する。
`lib/components/gateway.d2` で定義し、`...@../lib/bpmn` をインポートすれば使える。
ラベルは菱形の外上部 (`label.near: outside-top-center`) に配置される。

| クラス | BPMN 要素 |
|---|---|
| `exclusive-gateway` | 排他ゲートウェイ (XOR) |
| `parallel-gateway` | 並列ゲートウェイ (AND) |
| `inclusive-gateway` | 包含ゲートウェイ (OR) |
| `complex-gateway` | 複雑ゲートウェイ |
| `event-based-gateway` | イベント駆動ゲートウェイ |

### データ要素 (クラス / lib/components/data.d2)

データ関連の要素。`要素.class: クラス名` で適用する。
`lib/components/data.d2` で定義し、`...@../lib/bpmn` をインポートすれば使える。
D2 ネイティブ図形で描画するため SVG アイコンは使わない。

```d2
注文データ.class: data-object
注文データ: 注文データ
```

| クラス | BPMN 要素 | 表現 |
|---|---|---|
| `data-object` | データオブジェクト | 折り返し付き文書形 (`shape: page`, シアン) |
| `data-store` | データストア | 円筒形 (`shape: cylinder`, シアン) |
| `data-variation` | -(BPMN 規格外・本ライブラリ独自) | パッケージ形 (`shape: package`, シアン)。データの派生・亜種を表す |

### イベント種別 (クラス / lib/components/event.d2)

アイコン付きのイベント種別 (全 36種)。`要素.class: クラス名` で適用する。
`lib/components/event.d2` で定義し、`...@../lib/bpmn` をインポートすれば使える。

外枠 (開始 = 単一細枠 / 中間 = 二重円 / 終了 = 太枠) と種別アイコンが
SVG に含まれるため `shape: image` で表示される。
ラベルは円の外上部 (`label.near: outside-top-center`) に配置される。

開始イベント (単一細枠の円 + アイコン・9種):

| クラス | BPMN 要素 |
|---|---|
| `start-none-event` | 開始イベント (none) |
| `start-message-event` | メッセージ開始イベント |
| `start-timer-event` | タイマー開始イベント |
| `start-conditional-event` | 条件開始イベント |
| `start-signal-event` | シグナル開始イベント |
| `start-escalation-event` | エスカレーション開始イベント |
| `start-error-event` | エラー開始イベント |
| `start-multiple-event` | 複合開始イベント |
| `start-parallel-multiple-event` | 並列複合開始イベント |

中間イベント (二重円 + アイコン・18種):

| クラス | BPMN 要素 |
|---|---|
| `intermediate-none-event` | 中間イベント (none) |
| `intermediate-message-catch-event` | メッセージ中間キャッチイベント |
| `intermediate-message-throw-event` | メッセージ中間スローイベント |
| `intermediate-timer-catch-event` | タイマー中間キャッチイベント |
| `intermediate-conditional-catch-event` | 条件中間キャッチイベント |
| `intermediate-link-catch-event` | リンク中間キャッチイベント |
| `intermediate-link-throw-event` | リンク中間スローイベント |
| `intermediate-signal-catch-event` | シグナル中間キャッチイベント |
| `intermediate-signal-throw-event` | シグナル中間スローイベント |
| `intermediate-escalation-catch-event` | エスカレーション中間キャッチイベント |
| `intermediate-escalation-throw-event` | エスカレーション中間スローイベント |
| `intermediate-error-catch-event` | エラー中間キャッチイベント |
| `intermediate-compensation-catch-event` | 補償中間キャッチイベント |
| `intermediate-compensation-throw-event` | 補償中間スローイベント |
| `intermediate-cancel-catch-event` | キャンセル中間キャッチイベント |
| `intermediate-multiple-catch-event` | 複合中間キャッチイベント |
| `intermediate-multiple-throw-event` | 複合中間スローイベント |
| `intermediate-parallel-multiple-catch-event` | 並列複合中間キャッチイベント |

終了イベント (太枠の円 + アイコン・9種):

| クラス | BPMN 要素 |
|---|---|
| `end-none-event` | 終了イベント (none) |
| `end-message-event` | メッセージ終了イベント |
| `end-escalation-event` | エスカレーション終了イベント |
| `end-error-event` | エラー終了イベント |
| `end-cancel-event` | キャンセル終了イベント |
| `end-compensation-event` | 補償終了イベント |
| `end-signal-event` | シグナル終了イベント |
| `end-multiple-event` | 複合終了イベント |
| `end-terminate-event` | 打ち切り終了イベント (Terminate) |

### 接続に適用

`接続.class: クラス名` で適用する。`lib/components/stroke.d2` で定義し、
`...@../lib/bpmn` をインポートすれば使える。

| クラス | BPMN 要素 | 表現 |
|---|---|---|
| `sequence-flow` | シーケンスフロー | 実線 + 塗りつぶし矢印 |
| `message-flow` | メッセージフロー | 破線 (紫) + 始点白抜き円 + 終点白抜き矢印 (`<->` 接続で使用, プール間) |
| `association` | 関連 | 点線 + 矢印なし (`--` 接続で使用, 注釈などとの接続) |
| `data-association` | データ関連 | 点線 + 終点白抜き矢印 (データオブジェクトとの接続) |

## 書き方の例

```d2
...@../lib/bpmn

direction: right

# プール / レーンはテンプレートを部分import
プール: @../lib/components/container.pool
プール: プール
プール.レーン: @../lib/components/container.lane
プール.レーン: レーン
プール.レーン.開始.class: start-none-event
プール.レーン.開始: 開始
プール.レーン.判定.class: exclusive-gateway
プール.レーン.判定: 承認可否

# タスクはテンプレートを部分import
承認: @../lib/components/task.user-task
承認: 承認処理
承認.desc: 人間が確認して承認する

プール.レーン.完了.class: end-none-event
プール.レーン.完了: 完了
プール.レーン.開始 -> プール.レーン.判定
プール.レーン.判定 -> 承認: 可
承認 -> プール.レーン.完了
```

```d2
# ラベル付きメッセージフロー (始点円のため <-> で接続)
顧客.注文 <-> プール.レーン.承認: {
  class: message-flow
  label: 申請書
}
```

## BPMN との対応 (本ライブラリの規約)

| BPMN 記法 | 本ライブラリでの表現 |
|---|---|
| 開始イベント (細枠円) | `start-none-event` (種別付きは `start-<種別>-event`) |
| 中間イベント (二重円) | `intermediate-none-event` (種別付きは `intermediate-<種別>-catch/throw-event`) |
| 終了イベント (太枠円) | `end-none-event` (種別付きは `end-<種別>-event`) |
| 排他ゲートウェイ (× 付きひし形) | `exclusive-gateway` |
| 並列ゲートウェイ (+ 付きひし形) | `parallel-gateway` |
| 包含ゲートウェイ (○ 付きひし形) | `inclusive-gateway` |
| 複雑ゲートウェイ (✳ 付きひし形) | `complex-gateway` |
| イベント駆動ゲートウェイ | `event-based-gateway` |
| プール (境界 + 左ラベル帯) | `container.pool` テンプレート (ラベルは横書き・左中央で代用) |
| レーン (担当区分 + 左ラベル帯) | `container.lane` テンプレート (ラベルは横書き・左中央で代用) |
| 圧縮サブプロセス | `subprocess` (破線枠で代用) |
| シーケンスフロー (実線矢印) | `->` (必要なら `sequence-flow`) |
| メッセージフロー (破線矢印) | `<->` 接続 + `message-flow` |
| 関連 (点線) | `--` 接続 + `association` |
| データ関連 (点線矢印) | `data-association` |
| データオブジェクト (折り返し付き文書形) | `data-object` |
| データストア (円筒形) | `data-store` |
| データの派生・亜種 (本ライブラリ独自) | `data-variation` |

※ イベント・ゲートウェイの外枠とマーカーは SVG アイコンで描画する
  (shape: image)。イベントの単一円・二重円・太枠円も SVG に含まれる。

## 色のカスタマイズ

`lib/bpmn.d2` の `vars.bpmn` 配下のトークンのみ変更すれば全図に反映される。

| トークン | 内容 |
|---|---|
| `task-fill` / `task-stroke` | タスクの塗り / 枠線 |
| `task-icon-size` | タスクアイコン (marker) のサイズ |
| `pool-fill` / `pool-stroke` | プールの塗り / 枠線 |
| `lane-fill` / `lane-stroke` | レーンの塗り / 枠線 |
| `data-fill` / `data-stroke` | データ要素の塗り / 枠線 |
| `icon-dir` | アイコンディレクトリ (図ファイル基準の相対パス) |

※ `icon-dir` は部分import したテンプレート内のアイコンを図ファイルの位置から解決するためのもの。図を `examples/` / `templates/` 以外の階層に置く場合は図側で `vars.bpmn.icon-dir` を上書きすること。

## Make ターゲット

| コマンド | 内容 |
|---|---|
| `make fmt` | 全 `.d2` を整形 |
| `make check` | 全 `.d2` の構文検証 (`d2 validate`) |
| `make build` | テンプレートとサンプルを `out/` に SVG 出力 |
| `make watch` | ライブプレビュー。`FILE=` で対象指定 (デフォルト: `examples/order-process.d2`、ポート 39981 固定) |
| `make clean` | `out/` を削除 |
