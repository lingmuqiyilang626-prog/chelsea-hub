import type { Metadata } from "next";
import Link from "next/link";

import { PlayerCatalog } from "@/components/player-catalog";
import { getPlayers } from "@/data/players";

export const metadata: Metadata = {
  title: "選手図鑑",
  description: "Chelsea Hubに掲載している選手の一覧です。",
};

export default async function PlayersPage() {
  const players = await getPlayers();

  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <header className="border-b border-white/10 bg-[#001489]">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
          <Link
            href="/"
            className="text-xl font-bold tracking-wide focus-visible:rounded focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-200"
          >
            Chelsea Hub
          </Link>
          <span className="text-sm text-blue-100">Players</span>
        </div>
      </header>

      <section className="mx-auto max-w-6xl px-6 py-16 sm:py-20">
        <Link
          href="/"
          className="text-sm font-semibold text-blue-300 hover:text-blue-200 focus-visible:rounded focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-300"
        >
          ← トップへ戻る
        </Link>

        <div className="mt-8">
          <p className="font-semibold tracking-widest text-blue-400">
            PLAYER DIRECTORY
          </p>
          <h1 className="mt-3 text-4xl font-bold sm:text-5xl">選手図鑑</h1>
          <p className="mt-5 max-w-2xl leading-7 text-slate-300">
            Chelsea男子トップチームの登録選手{players.length}
            名を掲載しています。カードを選ぶと詳細を確認できます。
          </p>
        </div>

        <PlayerCatalog players={players} />
      </section>
    </main>
  );
}
