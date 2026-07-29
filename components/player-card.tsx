import Link from "next/link";

import type { Player } from "@/data/players";

type PlayerCardProps = {
  player: Player;
};

export function PlayerCard({ player }: PlayerCardProps) {
  return (
    <Link
      href={`/players/${player.slug}`}
      className="group block rounded-2xl focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-300"
      aria-label={`${player.name}の詳細を見る`}
    >
      <article className="h-full overflow-hidden rounded-2xl border border-white/10 bg-white/5 transition group-hover:-translate-y-1 group-hover:border-blue-400/60 group-hover:bg-white/10">
        <div className="flex aspect-[4/3] items-center justify-center bg-[radial-gradient(circle_at_top_right,_#2563eb,_#001489_48%,_#020617)]">
          <span
            aria-hidden="true"
            className="text-6xl font-black tracking-tight text-white/90"
          >
            {player.initials}
          </span>
        </div>

        <div className="p-6">
          <p className="text-sm font-semibold uppercase tracking-widest text-blue-300">
            {player.position}
          </p>
          <h2 className="mt-2 text-2xl font-bold text-white">{player.name}</h2>
          <p className="mt-3 text-sm leading-6 text-slate-300">
            {player.summary}
          </p>
          <p className="mt-5 font-semibold text-blue-300">プロフィールを見る →</p>
        </div>
      </article>
    </Link>
  );
}
