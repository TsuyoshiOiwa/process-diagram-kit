D2      := d2 --layout=tala
SRCS    := $(shell find lib templates examples works -name '*.d2' 2>/dev/null)
OUT_DIR := out
FILE    ?= examples/order-process.d2

.PHONY: fmt check build watch clean help

## fmt:    全 .d2 ファイルを整形する
fmt:
	@for f in $(SRCS); do $(D2) fmt $$f && echo "fmt: $$f"; done

## check:  全 .d2 ファイルの構文を検証する (CI 用)
check:
	@status=0; \
	for f in $(SRCS); do $(D2) validate $$f || status=1; done; \
	exit $$status

## build:  テンプレートとサンプルを out/ に SVG 出力する (動作検証)
build:
	@mkdir -p $(OUT_DIR)
	@status=0; \
	for f in templates/*.d2 examples/*.d2 works/*.d2 ; do \
		out=$(OUT_DIR)/$$(basename $${f%.d2}).svg; \
		$(D2) $$f $$out && echo "build: $$out" || status=1; \
	done; \
	exit $$status

## watch:  指定ファイルをライブプレビューする (make watch FILE=examples/foo.d2 / VS Code のポート転送で localhost:39981 を開く)
watch:
	@mkdir -p $(OUT_DIR)
	$(D2) --watch --browser 0 --port 39981 $(FILE) $(OUT_DIR)/$(notdir $(FILE:.d2=.svg))

## clean:  生成物を削除する
clean:
	rm -rf $(OUT_DIR)

## help:   Make ターゲットの一覧を表示する
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## //'
