import type { SquadNumberHistoryEntry } from "@/data/players";

type SquadNumberHistoryProps = {
  entries: SquadNumberHistoryEntry[];
};

function formatDateOnly(value: string) {
  const [year, month, day] = value.split("-").map(Number);
  return `${year}年${month}月${day}日`;
}

function previousDateOnly(value: string) {
  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  date.setUTCDate(date.getUTCDate() - 1);
  return date.toISOString().slice(0, 10);
}

function formatPeriod(entry: SquadNumberHistoryEntry) {
  const start = formatDateOnly(entry.validFrom);
  const end = entry.validTo
    ? formatDateOnly(previousDateOnly(entry.validTo))
    : "現在";

  return `${start}〜${end}`;
}

export function SquadNumberHistory({ entries }: SquadNumberHistoryProps) {
  if (entries.length === 0) {
    return null;
  }

  return (
    <section
      aria-labelledby="squad-number-history-heading"
      className="mt-10 rounded-3xl border border-white/10 bg-white/5 p-7 sm:p-9"
    >
      <p className="text-sm font-semibold uppercase tracking-widest text-blue-300">
        SQUAD NUMBER HISTORY
      </p>
      <h2 id="squad-number-history-heading" className="mt-2 text-2xl font-bold">
        背番号履歴
      </h2>

      <ol className="mt-7 space-y-6 border-l border-blue-400/40 pl-6">
        {entries.map((entry) => (
          <li
            key={`${entry.squadNumber}-${entry.validFrom}`}
            className="relative min-w-0 rounded-2xl border border-white/10 bg-slate-950/70 p-5 before:absolute before:-left-[1.9rem] before:top-7 before:h-3 before:w-3 before:rounded-full before:bg-blue-300 before:ring-4 before:ring-slate-950"
          >
            <div className="flex flex-wrap items-center gap-3">
              <p className="text-3xl font-black text-white">
                <span className="sr-only">背番号</span>
                {entry.squadNumber}
              </p>
              {entry.isCurrent && (
                <span className="rounded-full bg-blue-700 px-3 py-1 text-xs font-bold text-blue-50">
                  現在
                </span>
              )}
            </div>
            <p className="mt-2 text-sm leading-6 text-slate-300">
              {formatPeriod(entry)}
            </p>
            <div className="mt-4 border-t border-white/10 pt-4 text-sm">
              <a
                href={entry.source.url}
                target="_blank"
                rel="noopener noreferrer"
                className="break-words font-semibold text-blue-300 underline decoration-blue-300/50 underline-offset-4 hover:text-blue-200 focus-visible:rounded focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-blue-300"
              >
                {entry.source.publisher}公式出典（背番号{entry.squadNumber}）
                <span className="sr-only">（新しいタブで開く）</span>
              </a>
              <p className="mt-2 text-slate-400">
                情報確認日：{formatDateOnly(entry.source.checkedAt)}
              </p>
            </div>
          </li>
        ))}
      </ol>
    </section>
  );
}
