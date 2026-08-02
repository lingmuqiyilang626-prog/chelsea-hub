import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "Chelsea Hub",
    template: "%s | Chelsea Hub",
  },
  description: "チェルシーFCの選手やクラブ情報を紹介するファンデータベース。",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="ja"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        {children}
        <footer className="border-t border-white/10 bg-slate-950 px-6 py-8 text-slate-400">
          <div className="mx-auto max-w-6xl space-y-2 text-sm leading-6">
            <p>
              Chelsea Hubは個人が制作した非公式・非営利のファンプロジェクトです。
            </p>
            <p>
              Chelsea Football
              Clubおよびその関連団体とは、提携、承認、後援その他の関係はありません。
            </p>
            <p>第三者の商標その他の権利は、各権利者に帰属します。</p>
          </div>
        </footer>
      </body>
    </html>
  );
}
