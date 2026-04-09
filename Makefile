.PHONY: help setup upgrade format open clean build generate

# デフォルトターゲット - ヘルプの表示
help:
	@echo "利用可能なコマンド:"
	@echo "  make setup    - 開発環境をセットアップします（XcodeGen, SwiftFormat）"
	@echo "  make upgrade  - 開発環境ツールをアップグレードします（XcodeGen, SwiftFormat）"
	@echo "  make generate - XcodeGenでプロジェクトファイルを生成します"
	@echo "  make format   - SwiftFormatでコードをフォーマットします"
	@echo "  make open     - FloateingSights4var2.xcodeprojをXcodeで開きます"
	@echo "  make clean    - ビルド成果物をクリーンします"
	@echo "  make build    - プロジェクトをビルドします"
	@echo "  make help     - このヘルプを表示します"

# 開発環境のセットアップ（XcodeGen, SwiftFormat）
setup:
	@echo "開発環境をセットアップしています..."
	@which brew > /dev/null || (echo "Homebrewがインストールされていません。まずHomebrewをインストールしてください。" && exit 1)
	@echo "必要なツールをインストールしています..."
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
	@echo "セットアップが完了しました！"

# 開発環境ツールのバージョンアップ
upgrade:
	@echo "開発環境ツールのバージョンをアップグレードしています..."
	@which brew > /dev/null || (echo "Homebrewがインストールされていません。まずHomebrewをインストールしてください。" && exit 1)
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
	@echo "開発環境ツールのアップグレードが完了しました！"

# XcodeGenでプロジェクトファイルを生成
generate:
	@echo "XcodeGenでプロジェクトファイルを生成しています..."
	@if ! which xcodegen > /dev/null; then \
		echo "XcodeGenがインストールされていません。'make setup'を実行してください"; \
		exit 1; \
	fi
	cd FloateingSights4var2 && xcodegen generate
	@echo "プロジェクトファイルの生成が完了しました"

# SwiftFormatの実行
format:
	@echo "SwiftFormatでコードをフォーマットしています..."
	@if ! which swiftformat > /dev/null; then \
		echo "SwiftFormatがインストールされていません。'make setup'を実行してください"; \
		exit 1; \
	fi
	swiftformat FloateingSights4var2/

# ビルド成果物をクリーン
clean:
	@echo "ビルド成果物をクリーンしています..."
	xcodebuild clean -project FloateingSights4var2/FloateingSights4var2.xcodeproj -scheme FloateingSights4var2
	@echo "クリーンが完了しました"

# プロジェクトをビルド
build: generate
	@echo "プロジェクトをビルドしています..."
	xcodebuild build -project FloateingSights4var2/FloateingSights4var2.xcodeproj -scheme FloateingSights4var2
	@echo "ビルドが完了しました"

# XcodeでプロジェクトファイルをOpen
open: generate
	@echo "FloateingSights4var2.xcodeprojをXcodeで開いています..."
	open FloateingSights4var2/FloateingSights4var2.xcodeproj
