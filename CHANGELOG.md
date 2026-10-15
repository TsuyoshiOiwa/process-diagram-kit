# Changelog

## v0.2.0 (2026-10-15)

### 追加

- 独自拡張 (BPMN 非標準): 同一プール内の特定ユーザー宛ての非同期通知を表す要素
  - 通知イベント 4種: `start-notification-catch-event` /
    `intermediate-notification-catch-event` /
    `intermediate-notification-throw-event` / `end-notification-throw-event`
  - `notification-flow`: 同一プール内のレーン間の非同期通知フロー
    (破線・始点塗りつぶし円、`<->` 接続とセットで使用する)
  - 色トークン `vars.bpmn.notification-stroke` (#EA580C)
  - 通知ベル系 SVG アイコン 4種 (`lib/icons/`)
- 利用例 `examples/notification-flow.d2`

### 変更

- `make build` / `make buildpng` の出力先をソースのディレクトリ構造に
  合わせて出力するように変更 (例: `out/examples/notification-flow.svg`)
- `make build` で子フォルダ配下の `.d2` も再帰的にビルド可能に
  (各ファイルを `tmp/` 直下にコピーしてからビルドし `@../lib` の相対 import を解決)
- `make watch` で編集対象の実ファイルへのシンボリックリンクを `tmp/` に張り、
  import 解決と編集追跡を両立 (衝突回避のためランダム名)
- `make clean` で `tmp/` も削除
- 利用例を `examples/project/` 配下に再編成
  - `UC-01001` / `UC-01002` を削除
  - `BUC-01001` / `BUC-01002`、`UC-01004`〜`UC-01008`、`UC-03001` を追加
  - コンポーネントリスト (`component-list.md`) を更新

## v0.1.0 (2026-09-19)

- 初回リリース
  - BPMN 要素クラス (イベント / ゲートウェイ / データ要素 / フロー、アイコン SVG 付き 60 種以上)
  - プール / レーン / タスクの D2 テンプレート
  - 色トークンの集約 (`lib/bpmn.d2` の `vars.bpmn`)
  - opencode スキル `bpmn-diagram` / `bpmn-layout`
