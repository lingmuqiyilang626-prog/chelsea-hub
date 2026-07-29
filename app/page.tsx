import Link from "next/link";

const features = [
  {
    title: "選手図鑑",
    description: "チェルシーに所属する選手のプロフィールを確認できます。",
    href: "/players",
  },
  {
    title: "スタッフ図鑑",
    description: "監督・コーチ・スタッフ・経営陣の情報を掲載します。",
    href: null,
  },
  {
    title: "クラブ情報",
    description: "クラブの歴史、スタジアム、タイトルなどを紹介します。",
    href: null,
  },
];

export default function Home() {
  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <header className="border-b border-white/10 bg-[#001489]">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
          <h1 className="text-2xl font-bold tracking-wide">Chelsea Hub</h1>
          <span className="text-sm text-blue-100">Fan Database Project</span>
        </div>
      </header>

      <section className="mx-auto max-w-6xl px-6 py-24">
        <p className="mb-4 font-semibold tracking-widest text-blue-400">
          KEEP THE BLUE FLAG FLYING HIGH
        </p>

        <h2 className="max-w-3xl text-5xl font-bold leading-tight">
          チェルシーFCの情報を、
          <br />
          ひとつの場所に。
        </h2>

        <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">
          選手、スタッフ、クラブの歴史、試合情報を集約する
          チェルシー専門データベースです。
        </p>

        <a
          href="#contents"
          className="mt-10 inline-block rounded-lg bg-[#034694] px-6 py-3 font-semibold transition hover:bg-blue-600 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-300"
        >
          コンテンツを見る
        </a>
      </section>

      <section
        id="contents"
        className="mx-auto grid max-w-6xl gap-6 px-6 pb-24 md:grid-cols-3"
      >
        {features.map((feature) => (
          feature.href ? (
            <Link
              key={feature.title}
              href={feature.href}
              className="group rounded-2xl focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-300"
            >
              <article className="h-full rounded-2xl border border-white/10 bg-white/5 p-7 transition group-hover:border-blue-400/60 group-hover:bg-white/10">
                <h3 className="text-xl font-bold text-blue-300">
                  {feature.title}
                </h3>
                <p className="mt-3 leading-7 text-slate-400">
                  {feature.description}
                </p>
                <p className="mt-5 text-sm font-semibold text-blue-300">
                  選手を見る →
                </p>
              </article>
            </Link>
          ) : (
            <article
              key={feature.title}
              className="rounded-2xl border border-white/10 bg-white/5 p-7"
            >
              <h3 className="text-xl font-bold text-blue-300">
                {feature.title}
              </h3>
              <p className="mt-3 leading-7 text-slate-400">
                {feature.description}
              </p>
            </article>
          )
        ))}
      </section>
    </main>
  );
}
