# AGENTS.md

## プロジェクト概要

D2 (D2 Language) で BPMN 風の業務プロセス図を作成するためのテンプレート・クラス定義集。

- 管理対象は `.d2` ソースのみ。最終成果物 (SVG 等) はリポジトリで管理しない
- 要素定義の詳細 (テンプレート・クラスの一覧、BPMN との対応規約) は `README.md` を参照すること

## 前提ツール

| ツール | 用途 |
|---|---|
| d2 CLI (v0.8+) | コンパイル・整形・検証 (`--layout=tala` を使用) |
| VS Code 拡張 `terrastruct.d2` | エディタ内プレビュー・補完 |

## ディレクトリ構成

```
lib/bpmn.d2                  共通ライブラリのエントリポイント (色トークン vars + クラス定義 + 各コンポーネントの再公開)
lib/components/              要素別の定義ファイル (task / container / event / gateway / data / stroke)
lib/icons/                   BPMN マーカー SVG アイコン
templates/process.d2         新規図作成用テンプレート
examples/                    利用例・動作確認用の図
works/                       作業者が作成する図の作業フォルダ
out/                         ビルド成果物の出力先 (make clean で削除、管理対象外)
```

## コマンド

| コマンド | 内容 |
|---|---|
| `make fmt` | 全 `.d2` を整形 |
| `make check` | 全 `.d2` の構文検証 (`d2 validate`) |
| `make build` | テンプレートとサンプルを `out/` に SVG 出力 |
| `make watch` | ライブプレビュー (`FILE=` で対象指定、ポート 39981 固定) |
| `make clean` | `out/` を削除 |

## 作業時のルール

- BPMN 図 (`.d2`) を作成・編集するときは `bpmn-diagram` スキルを読み込む (新規図の作成手順・要素カタログ・接続・レイアウトの規約・D2 の制約はスキル側に集約している)
- 色やアイコンの指定は `lib/bpmn.d2` の `vars.bpmn` 配下のトークンに集約されている。コンポーネント定義に直接色を書かない
- イベント・ゲートウェイ・データ要素・接続 (フロー) のクラスは `lib/components/` 配下で定義し、`lib/bpmn.d2` 経由で利用できるようにする
