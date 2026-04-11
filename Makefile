.PHONY: help setup setup-linux upgrade format open clean build generate reset

# デフォルトターゲット - ヘルプの表示
help:
	@echo "利用可能なコマンド:"
	@echo "  make setup       - 開発環境をセットアップします（macOS: XcodeGen, SwiftFormat, Genesis, rbenv, Fastlane）"
	@echo "  make setup-linux - Linux用の開発環境をセットアップします（SwiftFormat）"
	@echo "  make upgrade  - 開発環境ツールをアップグレードします（XcodeGen, SwiftFormat）"
	@echo "  make generate - XcodeGenでプロジェクトファイルを生成します"
	@echo "  make format   - SwiftFormatでコードをフォーマットします"
	@echo "  make open     - FloatingSights.xcodeprojをXcodeで開きます（ルート）"
	@echo "  make clean    - ビルド成果物をクリーンします"
	@echo "  make build    - プロジェクトをビルドします"
	@echo "  make reset    - .envとproject.ymlを削除します"
	@echo "  make help     - このヘルプを表示します"

# 開発環境のセットアップ（XcodeGen, SwiftFormat, Genesis, rbenv, Fastlane）
setup:
	@echo "開発環境をセットアップしています..."
	@which brew > /dev/null || (echo "Homebrewがインストールされていません。まずHomebrewをインストールしてください。" && exit 1)
	@echo "必要なツールをインストールしています..."
	@if ! which mint > /dev/null; then \
		echo "Mintをインストール中..."; \
		brew install mint; \
	else \
		echo "Mintは既にインストール済み"; \
		mint version; \
	fi
	@echo "Genesisをインストール中..."
	@mint install yonaskolb/Genesis
	@if ! which xcodegen > /dev/null; then \
		echo "XcodeGenをインストール中..."; \
		brew install xcodegen; \
	else \
		echo "XcodeGenは既にインストール済み"; \
		xcodegen version; \
	fi
	@if ! which swiftformat > /dev/null; then \
		echo "SwiftFormatをインストール中..."; \
		brew install swiftformat; \
	else \
		echo "SwiftFormatは既にインストール済み"; \
		swiftformat --version; \
	fi
	@if ! which rbenv > /dev/null; then \
		echo "rbenvをインストール中..."; \
		brew install rbenv; \
	else \
		echo "rbenvは既にインストール済み"; \
	fi
	@eval "$$(rbenv init -)" && \
	RUBY_VERSION=$$(cat .ruby-version 2>/dev/null || echo "3.4.6") && \
	if ! rbenv versions | grep -q "$$RUBY_VERSION"; then \
		echo "Ruby $$RUBY_VERSION をインストール中..."; \
		brew upgrade ruby-build 2>/dev/null || true; \
		RUBY_CONFIGURE_OPTS="--with-openssl-dir=$$(brew --prefix openssl@3) --with-libyaml-dir=$$(brew --prefix libyaml)" \
		CFLAGS="-Wno-default-const-init-field-unsafe" \
		rbenv install "$$RUBY_VERSION"; \
	else \
		echo "Ruby $$RUBY_VERSION は既にインストール済み"; \
	fi && \
	rbenv local "$$(cat .ruby-version 2>/dev/null || echo "3.4.6")" && \
	echo "bundlerをインストール中..." && \
	gem install bundler --quiet && \
	echo "Fastlane（bundle install）を実行中..." && \
	bundle config set build.json '--with-cflags=-Wno-error=implicit-function-declaration' && \
	bundle install
	@if [ ! -f .env ]; then \
		echo ""; \
		echo "=== 初回セットアップ: ビルド設定を入力してください ==="; \
		printf "DEVELOPMENT_TEAM (Apple Team ID): "; \
		read DEVELOPMENT_TEAM; \
		printf "CODE_SIGN_STYLE (Automatic/Manual) [Automatic]: "; \
		read CODE_SIGN_STYLE; \
		CODE_SIGN_STYLE=$${CODE_SIGN_STYLE:-Automatic}; \
		printf "PRODUCT_BUNDLE_IDENTIFIER: "; \
		read PRODUCT_BUNDLE_IDENTIFIER; \
		printf "DEVELOPMENT_TEAM=$$DEVELOPMENT_TEAM\nCODE_SIGN_STYLE=$$CODE_SIGN_STYLE\nPRODUCT_BUNDLE_IDENTIFIER=$$PRODUCT_BUNDLE_IDENTIFIER\n" > .env; \
		echo ".envを作成しました"; \
	else \
		echo ".envは既に存在します（スキップ）"; \
	fi
	@echo "Genesisでproject.ymlを生成しています..."
	@set -a; . ./.env; set +a; \
	mint run yonaskolb/Genesis genesis generate genesis.yml --non-interactive
	@echo "セットアップが完了しました！"

# Linux用の開発環境セットアップ（SwiftFormat）
SWIFTFORMAT_VERSION := 0.60.1

setup-linux:
	@echo "Linux用の開発環境をセットアップしています..."
	@if [ "$$(uname)" != "Linux" ]; then \
		echo "このコマンドはLinux専用です。macOSでは 'make setup' を使用してください"; \
		exit 1; \
	fi
	@echo "SwiftFormat $(SWIFTFORMAT_VERSION) をインストール中..."
	@curl -sL https://github.com/nicklockwood/SwiftFormat/releases/download/$(SWIFTFORMAT_VERSION)/swiftformat_linux.zip -o /tmp/swiftformat.zip
	@unzip -o /tmp/swiftformat.zip -d /tmp/swiftformat
	@install -m 755 /tmp/swiftformat/swiftformat_linux /usr/local/bin/swiftformat
	@rm -rf /tmp/swiftformat /tmp/swiftformat.zip
	@echo "SwiftFormat $$(swiftformat --version) をインストールしました"
	@echo "セットアップが完了しました！"

# 開発環境ツールのバージョンアップ
upgrade:
	@echo "開発環境ツールのバージョンをアップグレードしています..."
	@which brew > /dev/null || (echo "Homebrewがインストールされていません。まずHomebrewをインストールしてください。" && exit 1)
	@if which mint > /dev/null; then \
		echo "Mintをアップグレード中..."; \
		brew upgrade mint || true; \
	else \
		echo "Mintがインストールされていません。'make setup'を実行してください"; \
	fi
	@if which mint > /dev/null; then \
		echo "Genesisをアップグレード中..."; \
		mint install yonaskolb/Genesis; \
	else \
		echo "Genesisがインストールされていません。'make setup'を実行してください"; \
	fi
	@if which xcodegen > /dev/null; then \
		echo "XcodeGenをアップグレード中..."; \
		brew upgrade xcodegen || true; \
	else \
		echo "XcodeGenがインストールされていません。'make setup'を実行してください"; \
	fi
	@if which swiftformat > /dev/null; then \
		echo "SwiftFormatをアップグレード中..."; \
		brew upgrade swiftformat || true; \
	else \
		echo "SwiftFormatがインストールされていません。'make setup'を実行してください"; \
	fi
	@if which rbenv > /dev/null; then \
		echo "rbenvをアップグレード中..."; \
		brew upgrade rbenv ruby-build || true; \
	else \
		echo "rbenvがインストールされていません。'make setup'を実行してください"; \
	fi
	@if which bundle > /dev/null; then \
		echo "Fastlane（bundle update）を実行中..."; \
		bundle update; \
	else \
		echo "bundlerがインストールされていません。'make setup'を実行してください"; \
	fi
	@echo "開発環境ツールのアップグレードが完了しました！"

# GenesisでXcodeGen設定を生成し、XcodeGenでプロジェクトファイルを生成
generate:
	@if [ ! -f .env ]; then \
		echo ".envが見つかりません。'make setup'を実行してください"; \
		exit 1; \
	fi
	@echo "Genesisでproject.ymlを生成しています..."
	@set -a; . ./.env; set +a; \
	mint run yonaskolb/Genesis genesis generate genesis.yml --non-interactive
	@echo "XcodeGenでプロジェクトファイルを生成しています..."
	@if ! which xcodegen > /dev/null; then \
		echo "XcodeGenがインストールされていません。'make setup'を実行してください"; \
		exit 1; \
	fi
	xcodegen generate
	@echo "プロジェクトファイルの生成が完了しました"

# SwiftFormatの実行
format:
	@echo "SwiftFormatでコードをフォーマットしています..."
	@if ! which swiftformat > /dev/null 2>&1; then \
		echo "SwiftFormatがインストールされていません。'make setup'を実行してください"; \
		exit 1; \
	fi
	swiftformat FloatingSights/

# ビルド成果物をクリーン
clean:
	@echo "ビルド成果物をクリーンしています..."
	xcodebuild clean -project FloatingSights.xcodeproj -scheme FloatingSights
	@echo "クリーンが完了しました"

# プロジェクトをビルド
build: generate
	@echo "プロジェクトをビルドしています..."
	xcodebuild build -project FloatingSights.xcodeproj -scheme FloatingSights
	@echo "ビルドが完了しました"

# .envとproject.ymlを削除してリセット
reset:
	@echo ".envとproject.ymlを削除しています..."
	rm -f .env project.yml
	@echo "削除が完了しました。再セットアップには 'make setup' を実行してください"

# XcodeでプロジェクトファイルをOpen
open: generate
	@echo "FloatingSights.xcodeprojをXcodeで開いています..."
	open FloatingSights.xcodeproj
