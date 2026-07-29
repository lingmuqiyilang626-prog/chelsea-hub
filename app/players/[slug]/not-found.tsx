import Link from "next/link";

export default function PlayerNotFound() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-950 px-6 text-white">
      <section className="max-w-lg text-center">
        <p className="font-semibold tracking-widest text-blue-400">404</p>
        <h1 className="mt-3 text-4xl font-bold">選手が見つかりません</h1>
        <p className="mt-5 leading-7 text-slate-300">
          指定された選手はChelsea Hub v0.1に登録されていません。
        </p>
        <Link
          href="/players"
          className="mt-8 inline-block rounded-lg bg-blue-700 px-6 py-3 font-semibold transition hover:bg-blue-600 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-300"
        >
          選手一覧へ戻る
        </Link>
      </section>
    </main>
  );
}
