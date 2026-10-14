---
name: bpmn-diagram
description: D2 による BPMN 業務プロセス図 (.d2) の作成・編集に使用。works/・examples/・templates/ 配下の .d2 におけるプール・レーン・タスク・イベント・ゲートウェイ・データ要素・フローの追加・修正、新規図の作成時にトリガーする。レイアウト (direction・top/left 等の座標調整) は対象外 (bpmn-layout スキル)。
---

# BPMN 図作成 (d2-bpmn)

- 完成イメージ: `examples/pizza-delivery.d2`
- 要素の実定義: `lib/components/*.d2` (本スキルと矛盾する場合は実定義を優先)
- レイアウト (direction・top/left 等の座標調整) は `bpmn-layout` スキルで扱う (タイトルの `title.near` は固定値のみ使用)

## 作成ワークフロー

1. `templates/process.d2` を `works/` にコピーして編集する (作成する図は `works/` に置く)
2. 編集したら `make fmt` で整形する
3. `make check` で構文検証する。SVG 出力は `make build` (templates / examples / works を対象に `out/` へ出力) か、
   単一ファイルは `./scripts/render.sh works/xxx.d2 svg` で確認する

## 基本骨格

図の先頭で共通ライブラリをインポートする (クラス・色トークンが有効化)。

```d2
...@../lib/bpmn
```

タイトルは md ブロック + `title.near: top-center` (固定値) で記述し、更新日時を記載する。

```d2
title: |md
  # ピザ配達
  更新日時: 2026/09/13
|
title.near: top-center
```

要素の指定方法は 2 種類ある (使い分けはカタログの「指定」列)。

- **テンプレート (部分import)**: タスク・プール・レーン。
  `要素: @../lib/components/<ファイル>.<名前>` のあとに `要素: ラベル` を重ね書きする
  (タスクのみ例外: ラベルを重ね書きせず、キー名 (要素 ID) をタスク名として使う)
- **クラス**: イベント・ゲートウェイ・データ要素・サブプロセス。
  `要素.class: クラス名` + `要素: ラベル`

色は図に直接書かない (クラス/テンプレートに集約。変更時は `lib/bpmn.d2` の `vars.bpmn`)。

## 要素カタログ

### コンテナ (テンプレート)

```d2
顧客: @../lib/components/container.pool
顧客: 顧客                 # プール名
営業: @../lib/components/container.lane
営業: 営業                 # レーン名 (プール内にネスト)
```

| テンプレート | BPMN 要素 |
|---|---|
| `container.pool` | プール (組織・システムの境界, 太枠) |
| `container.lane` | レーン (プール内の担当区分) |

### タスク (テンプレート)

キーに要素 ID (`TSK-001001` 等) を使う。ラベルは重ね書きせず、キー名 (要素 ID) を
タスク名としてそのまま表示し、処理内容は `desc.label` に書く (実例: `works/UC-01001.d2`)。

```d2
TSK-001001: @../lib/components/task.task
TSK-001001.desc.label: "知識原本を\nアップロードする"   # 説明文 (\n で改行)
```

| テンプレート | 内容 |
|---|---|
| `task.task` | 汎用タスク (アイコンなし) |
| `task.ad-hoc-task` | アドホックタスク |
| `task.loop-task` | ループタスク |
| `task.multi-instance-parallel-task` | 並列マルチインスタンスタスク |
| `task.multi-instance-sequential-task` | 逐次マルチインスタンスタスク |
| `task.compensation-task` | 補償タスク |

### イベント (クラス・36種 + 独自拡張 4種)

クラス名の規則: `start-<種別>-event` / `intermediate-<種別>-<catch|throw>-event` / `end-<種別>-event`

| 種別 | 開始 (細枠円) | 中間 (二重円) | 終了 (太枠円) |
|---|---|---|---|
| none | ○ | ○ (catch/throw なし) | ○ |
| message | ○ | catch / throw | ○ |
| timer | ○ | catch のみ | - |
| conditional | ○ | catch のみ | - |
| signal | ○ | catch / throw | ○ |
| escalation | ○ | catch / throw | ○ |
| error | ○ | catch のみ | ○ |
| multiple | ○ | catch / throw | ○ |
| parallel-multiple | ○ | catch のみ | - |
| link | - | catch / throw | - |
| compensation | - | catch / throw | ○ |
| cancel | - | catch のみ | ○ |
| terminate | - | - | ○ |
| notification (独自拡張) | catch のみ | catch / throw | throw のみ |

```d2
注文.class: start-none-event
注文: ピザが食べたい
焼成.class: intermediate-timer-catch-event
焼成: オーブンで焼成
食事.class: end-none-event
食事: 食事完了
```

notification は本ライブラリ独自拡張 (BPMN 非標準)。特定受信者宛ての非同期通知を
catch (受信) / throw (送信) で表す (ベルアイコン。throw は塗りつぶし)。

- 開始 catch (`start-notification-catch-event`): 通知の到着をトリガーにプロセスを開始する
- 中間 catch (`intermediate-notification-catch-event`): プロセス途中で通知の到着を待機する
- 中間 throw (`intermediate-notification-throw-event`): プロセス途中で通知を発行する (発行後も処理を継続)
- 終了 throw (`end-notification-throw-event`): プロセスの終了時に通知を発行する

※ 開始のみ他種別と異なりクラス名に catch を含める (catch / throw の対応を明示するため)

発行側 (タスクまたは throw イベント) と受信側は `notification-flow` で結ぶ
(詳細は本スキルの「独自拡張 (BPMN 非標準)」、実例: `examples/notification-flow.d2`)。

```d2
通知待ち.class: intermediate-notification-catch-event
通知待ち: 通知の到着を待つ

障害対応開始.class: start-notification-catch-event
障害対応開始: 障害通知の到着

通知発行.class: intermediate-notification-throw-event
通知発行: 通知を発行
```

### ゲートウェイ (クラス・5種)

| クラス | BPMN 要素 |
|---|---|
| `exclusive-gateway` | 排他 (XOR, 条件分岐) |
| `parallel-gateway` | 並列 (AND, 開始/合流) |
| `inclusive-gateway` | 包含 (OR, 複数条件分岐) |
| `complex-gateway` | 複雑条件 |
| `event-based-gateway` | イベント駆動分岐 |

### データ要素 (クラス・3種)

| クラス | 表現 |
|---|---|
| `data-object` | データオブジェクト (文書形) |
| `data-store` | データストア (円筒形) |
| `data-variation` | データの派生・亜種 (本ライブラリ独自・BPMN 規格外) |

### その他 (クラス)

| クラス | 内容 |
|---|---|
| `subprocess` | サブプロセス (破線枠の角丸矩形) |

### 独自拡張 (BPMN 非標準)

| クラス | 内容 |
|---|---|
| `start-notification-catch-event` | 通知開始イベント (catch。通知の到着をトリガーにプロセスを開始) |
| `intermediate-notification-catch-event` | 通知キャッチ中間イベント (catch。特定受信者宛ての非同期通知の到着待ち) |
| `intermediate-notification-throw-event` | 通知スロー中間イベント (throw。通知を発行し、処理は継続) |
| `end-notification-throw-event` | 通知スロー終了イベント (throw。プロセス終了時に通知を発行) |
| `notification-flow` | 通知フロー (同一プール内の非同期通知。レーン横断可・制御フローではない) |

catch = 受信側 (到着を待つ / 開始トリガーにする)、throw = 送信側 (通知を発行する)。
他種別と異なり開始イベントにも catch を名前に含む。

作成の動機: メッセージフローはプール間のみ接続可のため、同一プール内のレーン間
(レーン横断) の非同期連携を記述できなかった。notification-flow はこの制約を解消
するために設けたものであり、今後の仕様拡張も「同一プール内レーン間の非同期連携
の表現」を基本判断軸とする。

意味論上のルール:

1. notification-flow は同一プール内の要素間でのみ使用できる (プール間は message-flow を使う)
2. レーン横断可。シーケンスフローと同様にプール階層にフルパスで書く
3. notification-flow は制御フローではない (実行トークンを伝搬させない)。
   通知イベントの後続処理は sequence-flow で接続する
4. 中間 catch はプロセス途中での到着待ち、開始 catch は到着によるプロセス開始
   (インスタンス生成)、中間 throw は発行後も処理継続、終了 throw は発行と同時に
   プロセス終了を表す。到着と既読・確認は別概念として扱い、確認は catch 後続の
   タスクで表現する
5. 受信者の識別はレーン名だけに依存せず、通知の宛先情報で行う
6. 標準 BPMN 要素 (message-flow / sequence-flow / signal event など) の意味は変更しない

通知の属性 (D2 に独自属性を直接記述する方法はないため、ラベル・コメント・ドキュメントで表現する):

- `recipient`: 通知先
- `type`: 通知種別
- `correlationKey`: 業務処理との対応キー
- `deliveryMode`: `temporary` (一時) / `persistent` (永続。待機開始前に作成された通知も対象になり得る)
- `channel`: 通知経路

実例: `examples/notification-flow.d2`
(タスク → 中間 catch / 中間 throw → 開始 catch の 2 パターン)

## 接続 (フロー)

| クラス | 用途 | 接続構文 (クラスとセット) |
|---|---|---|
| `sequence-flow` | 同一プール内のフロー | `->` (クラス省略可: 既定で実線 + 塗り矢印) |
| `message-flow` | プール間のメッセージ | `<->` 必須 (始点円の表示に必要) |
| `association` | 関連 (矢印なし) | `--` 必須 |
| `data-association` | データ要素との接続 | `->` |
| `notification-flow` | 同一プール内の非同期通知 (独自拡張) | `<->` 必須 (始点円の表示に必要) |

```d2
# シーケンスフロー (ゲートウェイ分岐には条件ラベルを付ける)
注文受付 -> 注文確認
在庫確認 -> 注文処理依頼: あり

# メッセージフロー (プール間, 最上位階層に書く)
顧客.ピザ注文 <-> ピザ店.受付.注文受付: {
  class: message-flow
  label: ピザ注文
}

# 通知フロー (同一プール内・レーン横断, 独自拡張)
システム.通知登録 <-> ユーザー.通知待ち: {
  class: notification-flow
  label: 処理完了通知
}

# データ関連
注文確認 -> 注文情報1: { class: data-association }
```

BPMN 規則:

- シーケンスフローは同一プール内のみ (レーン横断は可)。メッセージフローはプール間のみ
- 通知フロー (独自拡張) は同一プール内のみ (レーン横断は可)。制御フローではないため
  実行トークンを伝搬させず、通知到着後の処理はシーケンスフローで接続する。プール間には使えない
- ゲートウェイの分岐先フローには条件ラベル (`: 前払い` 等) を付ける
- 開始イベントは細枠円・中間は二重円・終了は太枠円。catch (受信・待機) と throw (送信・発生) を種別で区別する
- データオブジェクトはタスクへ入力 (`データ -> タスク`)・タスクから出力 (`タスク -> データ`) で data-association 接続する
- レーン横断のフロー (シーケンス / 通知) はプールの階層でフルパスを書く (`受付.注文確認 -> 調理.調理開始`)
- メッセージフローは最上位階層に書き、両端をフルパスで指定する
- データオブジェクトは使用するレーン内に定義する。同一図内の同名データは番号で区別する
  (`注文情報1` / `注文情報2`)。ラベルは md ブロックで詳細も書ける

## D2 の仕様上の制約

- アイコン (marker) の位置はレイアウトエンジンが決める (座標指定は不可)
- コンテナのサイズは子要素とパディングから自動決定される (最小値の指定は不可)
- タスク名・説明文 (`desc.label`) は自動折返ししない (長い場合はダブルクォート内の `\n` で改行する)
- 縦書き不可のため、プール・レーンのラベル帯は横書き・左中央で代用される
- `works/` は `lib/` と同階層のため `vars.bpmn.icon-dir` の上書きは不要。
  それ以外の階層に図を置く場合のみ図側で `icon-dir` を上書きする
