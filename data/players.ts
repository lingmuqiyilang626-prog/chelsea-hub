export type Player = {
  slug: string;
  name: string;
  initials: string;
  position: string;
  nationality: string;
  squadNumber: number | null;
  dateOfBirth: string | null;
  heightCm: number | null;
  joinedAt: string | null;
  contractUntil: string | null;
  summary: string;
  sourceUrl: string;
  checkedAt: string;
};

export const players: Player[] = [
  {
    slug: "cole-palmer",
    name: "Cole Palmer",
    initials: "CP",
    position: "攻撃的ミッドフィールダー／ウインガー",
    nationality: "イングランド",
    squadNumber: 10,
    dateOfBirth: null,
    heightCm: null,
    joinedAt: null,
    contractUntil: null,
    summary:
      "狭い局面での創造性と、得点に関わるプレーを持ち味とする攻撃的な選手です。",
    sourceUrl: "https://www.chelseafc.com/en/teams/profile/cole-palmer",
    checkedAt: "2026-07-29",
  },
  {
    slug: "moises-caicedo",
    name: "Moises Caicedo",
    initials: "MC",
    position: "ミッドフィールダー",
    nationality: "エクアドル",
    squadNumber: 25,
    dateOfBirth: null,
    heightCm: null,
    joinedAt: null,
    contractUntil: null,
    summary:
      "中盤でボールを奪い、攻守のつながりを支える運動量豊富な選手です。",
    sourceUrl: "https://www.chelseafc.com/en/teams/profile/moises-caicedo",
    checkedAt: "2026-07-29",
  },
  {
    slug: "reece-james",
    name: "Reece James",
    initials: "RJ",
    position: "ディフェンダー",
    nationality: "イングランド",
    squadNumber: null,
    dateOfBirth: null,
    heightCm: null,
    joinedAt: null,
    contractUntil: null,
    summary:
      "守備と前進の両面でチームを支える、アカデミー出身の選手です。",
    sourceUrl: "https://www.chelseafc.com/en/teams/profile/reece-james",
    checkedAt: "2026-07-29",
  },
];

export function getPlayerBySlug(slug: string) {
  return players.find((player) => player.slug === slug);
}
