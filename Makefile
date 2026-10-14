D2      := d2 --layout=tala --font-regular=./fonts/opentype/ipafont-gothic/ipag.ttf
SRCS    := $(shell find lib templates examples works -name '*.d2' 2>/dev/null)
OUT_DIR := out
TMP_DIR := tmp
FILE    ?= examples/pizza-delivery.d2
FMT     ?= svg

.PHONY: fmt check build buildpng watch clean help

## fmt:    全 .d2 ファイルを整形する
fmt:
	@for f in $(SRCS); do $(D2) fmt $$f && echo "fmt: $$f"; done

## check:  全 .d2 ファイルの構文を検証する (CI 用)
check:
	@status=0; \
	for f in $(SRCS); do $(D2) validate $$f || status=1; done; \
	exit $$status

## build:  テンプレート・サンプル・works の全 .d2 を out/ に SVG 出力する (子フォルダ再帰対応)
##         各ファイルを tmp/ 直下にコピーしてからビルドすることで @../lib の相対 import を解決する
build:
	@mkdir -p $(TMP_DIR)
	@status=0; \
	for f in $$(find templates examples works -name '*.d2' 2>/dev/null); do \
		src=$(TMP_DIR)/$$(basename $$f); \
		cp $$f $$src; \
		out=$(OUT_DIR)/$${f%.d2}.$(FMT); \
		mkdir -p $$(dirname $$out); \
		$(D2) $$src $$out && echo "build: $$out" || status=1; \
	done; \
	rm -rf $(TMP_DIR); \
	exit $$status

## buildpng:  build の PNG 出力版 (make buildpng)
buildpng:
	@$(MAKE) build FMT=png

## watch:  指定ファイルをライブプレビューする (make watch FILE=examples/foo.d2 / VS Code のポート転送で localhost:39981 を開く)
##         実ファイルへのシンボリックリンクを tmp/ に張り (衝突回避のためランダム名) import 解決と編集追跡を両立する
watch:
	@mkdir -p $(TMP_DIR)
	@link=$(TMP_DIR)/watch-$$(date +%s%N)-$(notdir $(FILE)); \
	ln -sfn "$(CURDIR)/$(FILE)" "$$link"; \
	out=$(OUT_DIR)/$${FILE%.d2}.svg; \
	mkdir -p $$(dirname "$$out"); \
	$(D2) --watch --browser 0 --port 39981 "$$link" "$$out"

## clean:  生成物を削除する
clean:
	rm -rf $(OUT_DIR) $(TMP_DIR)

## help:   Make ターゲットの一覧を表示する
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## //'
