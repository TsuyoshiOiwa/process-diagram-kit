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

### イベント (クラス・36種)

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

```d2
注文.class: start-none-event
注文: ピザが食べたい
焼成.class: intermediate-timer-catch-event
焼成: オーブンで焼成
食事.class: end-none-event
食事: 食事完了
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

## 接続 (フロー)

| クラス | 用途 | 接続構文 (クラスとセット) |
|---|---|---|
| `sequence-flow` | 同一プール内のフロー | `->` (クラス省略可: 既定で実線 + 塗り矢印) |
| `message-flow` | プール間のメッセージ | `<->` 必須 (始点円の表示に必要) |
| `association` | 関連 (矢印なし) | `--` 必須 |
| `data-association` | データ要素との接続 | `->` |

```d2
# シーケンスフロー (ゲートウェイ分岐には条件ラベルを付ける)
注文受付 -> 注文確認
在庫確認 -> 注文処理依頼: あり

# メッセージフロー (プール間, 最上位階層に書く)
顧客.ピザ注文 <-> ピザ店.受付.注文受付: {
  class: message-flow
  label: ピザ注文
}

# データ関連
注文確認 -> 注文情報1: { class: data-association }
```

BPMN 規則:

- シーケンスフローは同一プール内のみ (レーン横断は可)。メッセージフローはプール間のみ
- ゲートウェイの分岐先フローには条件ラベル (`: 前払い` 等) を付ける
- 開始イベントは細枠円・中間は二重円・終了は太枠円。catch (受信・待機) と throw (送信・発生) を種別で区別する
- データオブジェクトはタスクへ入力 (`データ -> タスク`)・タスクから出力 (`タスク -> データ`) で data-association 接続する
- レーン横断のフローはプールの階層でフルパスを書く (`受付.注文確認 -> 調理.調理開始`)
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
