# Chelsea Hub

Chelsea Hubは、Chelsea Football Clubの選手やクラブ情報を日本語で紹介する、個人制作のファンデータベースです。

公開URL: https://chelsea-hub.vercel.app/

## 制作目的

チェルシーに関する基本情報を、見やすく確認できる場所にまとめることを目的としています。現在は男子トップチームの選手図鑑を中心に公開しています。

## 現在の機能

- Chelsea Hubの概要とコンテンツ入口を表示するトップページ
- 名前検索とポジション絞り込みに対応した選手一覧
- Supabaseから取得した男子トップチーム42名の詳細ページ
- 登録されていない選手URLに対する専用404表示
- スマートフォンを含む画面幅に応じたレイアウト

スタッフ図鑑、クラブ情報、試合情報などは今後の候補であり、現在は未実装です。

## 掲載選手

2026-08-16時点でChelsea FC公式男子プロフィール一覧のmensteam分類に含まれる42名を掲載しています。選手の所属やプロフィール情報は基準日時点のものです。

## 技術構成

- Next.js 16（App Router）
- React 19
- TypeScript
- Tailwind CSS 4
- ESLint
- Supabase
- Vercel

## ローカルでの起動方法

Node.jsとnpmを用意し、リポジトリを取得したディレクトリで次を実行します。

```bash
npm ci
```

起動前に`.env.example`を参考にルートへ`.env.local`を作成し、リンク済みSupabaseプロジェクトの公開読み取り用設定を指定してください。値はGitへコミットしません。

```dotenv
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
```

その後、開発サーバーを起動します。

```bash
npm run dev
```

ブラウザで http://localhost:3000/ を開いてください。

品質確認用のコマンドは次のとおりです。

```bash
npm run lint
npm run build
```

## Supabase migration

DB変更と初期公開データは`supabase/migrations`で管理します。適用前に`npx supabase migration list`と`npx supabase db push --dry-run`で対象を確認し、確認後に`npx supabase db push`を実行します。既存migrationは変更せず、新しい変更は新規migrationとして追加します。

## 主なURL

| URL | 内容 |
| --- | --- |
| `/` | トップページ |
| `/players` | 男子トップチーム42名の一覧・検索・ポジション絞り込み |
| `/players/cole-palmer` | Cole Palmerの詳細 |
| `/players/robert-sanchez` | Robert Sanchezの詳細 |

## 情報源と確認日の管理方針

選手情報はChelsea FC公式プロフィールなど、出典を確認できる情報を優先します。各選手データには参照先URLと情報確認日を保持し、詳細ページに表示します。情報は確認日時点のものであり、移籍、背番号、契約状況などの変更が即時に反映されるとは限りません。

## 写真とクラブエンブレムについて

現在は、肖像権、著作権、商標権など第三者の権利を尊重し、利用条件が明確でない選手写真やChelsea FCのクラブエンブレムを使用していません。選手画像の代わりに氏名のイニシャルを表示しています。

## 今後の予定

- 掲載選手と選手情報の拡充
- 情報源と確認日の継続的な更新
- アクセシビリティとレスポンシブ表示の改善
- スタッフ図鑑やクラブ情報の設計・実装検討

## 非公式・非提携表示

Chelsea Hubは個人が制作した非公式・非営利のファンプロジェクトです。Chelsea Football Clubおよびその関連団体とは、提携、承認、後援その他の関係はありません。第三者の商標その他の権利は、各権利者に帰属します。

## ライセンス

MIT Licenseは、このリポジトリ内の自作ソースコードにのみ適用されます。第三者の商標、名称、データ、画像、リンク先コンテンツなどに関する権利を付与するものではありません。ライセンス本文は[LICENSE](./LICENSE)を参照してください。
