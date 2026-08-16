"use client";

import { useMemo, useState } from "react";

import { PlayerCard } from "@/components/player-card";
import type { Player, PositionGroup } from "@/data/players";

type PlayerCatalogProps = {
  players: Player[];
};

type PositionFilter = "all" | PositionGroup;

const positionFilters: Array<{ label: string; value: PositionFilter }> = [
  { label: "すべて", value: "all" },
  { label: "GK", value: "goalkeeper" },
  { label: "DF", value: "defender" },
  { label: "MF", value: "midfielder" },
  { label: "FW", value: "forward" },
];

function normalizeSearchText(value: string) {
  return value.trim().replace(/\s+/g, " ").toLocaleLowerCase();
}

export function PlayerCatalog({ players }: PlayerCatalogProps) {
  const [query, setQuery] = useState("");
  const [positionFilter, setPositionFilter] =
    useState<PositionFilter>("all");

  const filteredPlayers = useMemo(() => {
    const normalizedQuery = normalizeSearchText(query);

    return players.filter((player) => {
      const matchesName = normalizeSearchText(player.name).includes(
        normalizedQuery,
      );
      const matchesPosition =
        positionFilter === "all" || player.positionGroup === positionFilter;

      return matchesName && matchesPosition;
    });
  }, [players, positionFilter, query]);

  const hasActiveFilters = query.length > 0 || positionFilter !== "all";

  function resetFilters() {
    setQuery("");
    setPositionFilter("all");
  }

  return (
    <div className="mt-12">
      <div className="rounded-2xl border border-white/10 bg-white/5 p-4 sm:p-6">
        <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-end">
          <div>
            <label
              htmlFor="player-search"
              className="text-sm font-semibold text-slate-200"
            >
              選手名で検索
            </label>
            <input
              id="player-search"
              type="search"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="例: Cole Palmer"
              className="mt-2 block w-full rounded-lg border border-white/15 bg-slate-950 px-4 py-3 text-base text-white placeholder:text-slate-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-300"
            />
          </div>

          <fieldset className="min-w-0">
            <legend className="text-sm font-semibold text-slate-200">
              ポジション
            </legend>
            <div className="mt-2 flex flex-wrap gap-2">
              {positionFilters.map((filter) => {
                const isSelected = positionFilter === filter.value;

                return (
                  <button
                    key={filter.value}
                    type="button"
                    aria-pressed={isSelected}
                    onClick={() => setPositionFilter(filter.value)}
                    className={`rounded-lg px-4 py-2 text-sm font-semibold transition focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-300 ${
                      isSelected
                        ? "bg-blue-600 text-white"
                        : "bg-white/10 text-slate-200 hover:bg-white/15"
                    }`}
                  >
                    {filter.label}
                  </button>
                );
              })}
            </div>
          </fieldset>
        </div>

        <div className="mt-5 flex flex-wrap items-center justify-between gap-3 border-t border-white/10 pt-4">
          <p className="text-sm text-slate-300" aria-live="polite">
            表示中 {filteredPlayers.length}名 / 全{players.length}名
          </p>
          <button
            type="button"
            onClick={resetFilters}
            disabled={!hasActiveFilters}
            className="rounded-lg border border-white/15 px-4 py-2 text-sm font-semibold text-slate-200 transition hover:bg-white/10 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-300 disabled:cursor-not-allowed disabled:opacity-40"
          >
            条件をリセット
          </button>
        </div>
      </div>

      {filteredPlayers.length > 0 ? (
        <div className="mt-8 grid grid-cols-1 gap-6 md:grid-cols-3">
          {filteredPlayers.map((player) => (
            <PlayerCard key={player.slug} player={player} />
          ))}
        </div>
      ) : (
        <div
          className="mt-8 rounded-2xl border border-dashed border-white/20 bg-white/5 px-6 py-12 text-center text-slate-300"
          role="status"
        >
          条件に一致する選手が見つかりませんでした。
        </div>
      )}
    </div>
  );
}
