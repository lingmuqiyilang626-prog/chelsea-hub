import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { getPlayerBySlug, getPlayerSlugs } from "@/data/players";

type PlayerPageProps = {
  params: Promise<{ slug: string }>;
};

export async function generateStaticParams() {
  const slugs = await getPlayerSlugs();
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: PlayerPageProps): Promise<Metadata> {
  const { slug } = await params;
  const player = await getPlayerBySlug(slug);

  if (!player) {
    return { title: "選手が見つかりません" };
  }

  return {
    title: player.name,
    description: player.summary ?? `${player.name}の選手プロフィールです。`,
  };
}

export default async function PlayerPage({ params }: PlayerPageProps) {
  const { slug } = await params;
  const player = await getPlayerBySlug(slug);

  if (!player) {
    notFound();
  }

  const details = [
    { label: "ポジション", value: player.position },
    { label: "国籍", value: player.nationality },
    { label: "背番号", value: player.squadNumber },
    { label: "生年月日", value: player.dateOfBirth },
    {
      label: "身長",
      value: player.heightCm === null ? null : `${player.heightCm} cm`,
    },
    { label: "加入日", value: player.joinedAt },
    { label: "契約期限", value: player.contractUntil },
  ].filter((detail) => detail.value !== null);

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
          <span className="text-sm text-blue-100">Player Profile</span>
        </div>
      </header>

      <article className="mx-auto max-w-5xl px-6 py-12 sm:py-16">
        <Link
          href="/players"
          className="text-sm font-semibold text-blue-300 hover:text-blue-200 focus-visible:rounded focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-300"
        >
          ← 選手一覧へ戻る
        </Link>

        <div className="mt-8 grid gap-8 lg:grid-cols-[minmax(0,0.8fr)_minmax(0,1.2fr)]">
          <div className="flex min-h-72 items-center justify-center rounded-3xl border border-white/10 bg-[radial-gradient(circle_at_top_right,_#2563eb,_#001489_48%,_#020617)] sm:min-h-96">
            <span
              aria-hidden="true"
              className="text-8xl font-black tracking-tight text-white/90 sm:text-9xl"
            >
              {player.initials}
            </span>
          </div>

          <div className="rounded-3xl border border-white/10 bg-white/5 p-7 sm:p-9">
            <p className="font-semibold uppercase tracking-widest text-blue-300">
              {player.position}
            </p>
            <h1 className="mt-3 text-4xl font-bold sm:text-5xl">
              {player.name}
            </h1>
            {player.summary && (
              <p className="mt-6 leading-8 text-slate-300">{player.summary}</p>
            )}

            <dl className="mt-8 grid gap-px overflow-hidden rounded-2xl border border-white/10 bg-white/10 sm:grid-cols-2">
              {details.map((detail, index) => (
                <div
                  key={detail.label}
                  className={`bg-slate-950/80 p-4 ${
                    details.length % 2 === 1 && index === details.length - 1
                      ? "sm:col-span-2"
                      : ""
                  }`}
                >
                  <dt className="text-sm text-slate-400">{detail.label}</dt>
                  <dd className="mt-1 font-semibold text-white">
                    {detail.value}
                  </dd>
                </div>
              ))}
            </dl>
            <p className="mt-3 text-sm leading-6 text-slate-400">
              公式プロフィールで確認できた情報のみ掲載しています。
            </p>

            <div className="mt-8 border-t border-white/10 pt-6">
              <p className="text-sm text-slate-400">
                情報確認日：{player.checkedAt}
              </p>
              <a
                href={player.sourceUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-3 inline-flex rounded-lg bg-blue-700 px-5 py-3 font-semibold text-white transition hover:bg-blue-600 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-300"
              >
                Chelsea FC公式プロフィール
                <span className="sr-only">（新しいタブで開く）</span>
              </a>
            </div>
          </div>
        </div>
      </article>
    </main>
  );
}
