import "server-only";

import { cache } from "react";

import { createServerSupabaseClient } from "@/lib/supabase/server";

export type Player = {
  slug: string;
  name: string;
  initials: string;
  position: string;
  positionGroup: PositionGroup;
  nationality: string | null;
  squadNumber: number | null;
  dateOfBirth: string | null;
  heightCm: number | null;
  joinedAt: string | null;
  contractUntil: string | null;
  summary: string | null;
  squadNumberHistory: SquadNumberHistoryEntry[];
  sourceUrl: string;
  checkedAt: string;
};

export type SquadNumberHistoryEntry = {
  squadNumber: number;
  validFrom: string;
  validTo: string | null;
  isCurrent: boolean;
  changeType: SquadNumberChangeType;
  source: {
    publisher: string;
    url: string;
    checkedAt: string;
  };
};

export type SquadNumberChangeType = "actual_change" | "correction";

export type PositionGroup =
  | "goalkeeper"
  | "defender"
  | "midfielder"
  | "forward";

type PersonRow = {
  display_name: string;
  id: string;
  slug: string;
};

type ProfileRow = {
  date_of_birth: string | null;
  height_cm: number | null;
  nationality: string | null;
  person_id: string;
  position_group: PositionGroup | null;
  primary_position: string | null;
  source_id: string | null;
  summary: string | null;
};

type RoleRow = {
  person_id: string;
  valid_from: string | null;
  valid_to: string | null;
};

type SourceRow = {
  id: string;
  publisher: string | null;
  retrieved_at: string | null;
  url: string;
};

type SquadNumberRow = {
  person_id: string;
  squad_number: number;
  valid_from: string;
  valid_to: string | null;
};

type SquadNumberHistoryRow = SquadNumberRow & {
  change_type: string;
  source_id: string | null;
};

function throwOnSupabaseError(context: string, error: { message: string } | null) {
  if (error) {
    throw new Error(`Failed to load ${context} from Supabase: ${error.message}`);
  }
}

function requireText(value: string | null, field: string, personId: string) {
  if (!value?.trim()) {
    throw new Error(`Missing required ${field} for public player ${personId}`);
  }

  return value;
}

function createInitials(name: string) {
  const parts = name.trim().split(/\s+/);

  if (parts.length < 2) {
    throw new Error(`Cannot create initials for public player: ${name}`);
  }

  return `${parts[0][0]}${parts.at(-1)?.[0]}`.toUpperCase();
}

const japaneseNationalityByCanonicalValue: Record<string, string> = {
  American: "アメリカ合衆国",
  Argentinian: "アルゼンチン",
  Belgian: "ベルギー",
  Brazilian: "ブラジル",
  Dutch: "オランダ",
  Ecuadorian: "エクアドル",
  English: "イングランド",
  French: "フランス",
  Italian: "イタリア",
  Portuguese: "ポルトガル",
  Senegalese: "セネガル",
  Spanish: "スペイン",
  Ukrainian: "ウクライナ",
};

function toJapaneseNationality(value: string | null, personId: string) {
  if (!value?.trim()) {
    return null;
  }

  const translated = japaneseNationalityByCanonicalValue[value];

  if (!translated) {
    throw new Error(
      `Missing Japanese nationality label for public player ${personId}: ${value}`,
    );
  }

  return translated;
}

function toCheckedAt(retrievedAt: string | null, context: string) {
  if (!retrievedAt) {
    throw new Error(`Missing source retrieved_at for ${context}`);
  }

  const checkedAt = retrievedAt.slice(0, 10);

  if (!/^\d{4}-\d{2}-\d{2}$/.test(checkedAt)) {
    throw new Error(`Invalid source retrieved_at for ${context}`);
  }

  return checkedAt;
}

function requireDateOnly(value: string | null, field: string, personId: string) {
  if (!value || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new Error(`Missing or invalid ${field} for public player ${personId}`);
  }

  return value;
}

function toSquadNumberChangeType(
  value: string,
  personId: string,
): SquadNumberChangeType {
  if (value !== "actual_change" && value !== "correction") {
    throw new Error(
      `Invalid squad number change_type for public player ${personId}: ${value}`,
    );
  }

  return value;
}

function createSquadNumberHistoryByPersonId(
  rows: SquadNumberHistoryRow[],
  currentRows: SquadNumberRow[],
  sourceById: Map<string, SourceRow>,
) {
  const currentKeyByPersonId = new Map<string, string>();

  for (const current of currentRows) {
    const validFrom = requireDateOnly(
      current.valid_from,
      "current squad number valid_from",
      current.person_id,
    );
    const key = `${current.squad_number}:${validFrom}:${current.valid_to ?? ""}`;

    if (currentKeyByPersonId.has(current.person_id)) {
      throw new Error(
        `Duplicate current squad number for public player ${current.person_id}`,
      );
    }

    currentKeyByPersonId.set(current.person_id, key);
  }

  const rowsByPersonId = new Map<string, SquadNumberHistoryRow[]>();

  for (const row of rows) {
    const personRows = rowsByPersonId.get(row.person_id) ?? [];
    personRows.push(row);
    rowsByPersonId.set(row.person_id, personRows);
  }

  const historyByPersonId = new Map<string, SquadNumberHistoryEntry[]>();

  for (const [personId, personRows] of rowsByPersonId) {
    const sortedRows = [...personRows].sort((left, right) =>
      left.valid_from.localeCompare(right.valid_from),
    );
    let previousValidTo: string | null | undefined;

    const entries = sortedRows.map((row) => {
      const validFrom = requireDateOnly(
        row.valid_from,
        "squad number valid_from",
        personId,
      );
      const validTo = row.valid_to
        ? requireDateOnly(row.valid_to, "squad number valid_to", personId)
        : null;

      if (
        !Number.isInteger(row.squad_number) ||
        row.squad_number < 1 ||
        row.squad_number > 99
      ) {
        throw new Error(`Invalid squad number for public player ${personId}`);
      }

      if (validTo && validTo <= validFrom) {
        throw new Error(`Invalid squad number period for public player ${personId}`);
      }

      if (previousValidTo === null || (previousValidTo && previousValidTo > validFrom)) {
        throw new Error(`Overlapping squad number periods for public player ${personId}`);
      }

      previousValidTo = validTo;

      const sourceId = requireText(row.source_id, "squad number source", personId);
      const source = sourceById.get(sourceId);

      if (!source) {
        throw new Error(`Missing public squad number source row for ${personId}`);
      }

      const currentKey = `${row.squad_number}:${validFrom}:${validTo ?? ""}`;

      return {
        squadNumber: row.squad_number,
        validFrom,
        validTo,
        isCurrent: currentKeyByPersonId.get(personId) === currentKey,
        changeType: toSquadNumberChangeType(row.change_type, personId),
        source: {
          publisher: requireText(source.publisher, "source publisher", personId),
          url: requireText(source.url, "squad number source URL", personId),
          checkedAt: toCheckedAt(
            source.retrieved_at,
            `public player ${personId} squad number`,
          ),
        },
      };
    });

    const currentKey = currentKeyByPersonId.get(personId);

    if (currentKey && !entries.some((entry) => entry.isCurrent)) {
      throw new Error(`Current squad number has no history row for ${personId}`);
    }

    historyByPersonId.set(personId, entries);
  }

  for (const personId of currentKeyByPersonId.keys()) {
    if (!historyByPersonId.get(personId)?.some((entry) => entry.isCurrent)) {
      throw new Error(`Current squad number has no history row for ${personId}`);
    }
  }

  return historyByPersonId;
}

function indexUniqueRows<T>(
  rows: T[],
  getKey: (row: T) => string,
  context: string,
) {
  const index = new Map<string, T>();

  for (const row of rows) {
    const key = getKey(row);

    if (index.has(key)) {
      throw new Error(`Duplicate ${context} for public player ${key}`);
    }

    index.set(key, row);
  }

  return index;
}

const loadPlayers = cache(async (): Promise<Player[]> => {
  const supabase = createServerSupabaseClient();

  const { data: club, error: clubError } = await supabase
    .from("clubs")
    .select("id")
    .eq("slug", "chelsea-football-club")
    .single();
  throwOnSupabaseError("Chelsea Football Club", clubError);

  if (!club) {
    throw new Error("Supabase returned no public Chelsea Football Club");
  }

  const { data: team, error: teamError } = await supabase
    .from("public_teams")
    .select("id")
    .eq("club_id", club.id)
    .eq("slug", "first-team")
    .eq("team_level", "first_team")
    .single();
  throwOnSupabaseError("Chelsea First Team", teamError);

  if (!team) {
    throw new Error("Supabase returned no public Chelsea First Team");
  }

  const { data: squadRoleData, error: squadRoleError } = await supabase
    .from("current_public_role_assignments")
    .select("person_id, valid_from, valid_to")
    .eq("club_id", club.id)
    .eq("team_id", team.id)
    .eq("role_type", "player")
    .eq("assignment_type", "squad");
  throwOnSupabaseError("Chelsea First Team player assignments", squadRoleError);

  const squadRoles = squadRoleData as RoleRow[];

  if (squadRoles.length === 0) {
    throw new Error("Supabase returned no public Chelsea First Team players");
  }

  const squadRoleByPersonId = indexUniqueRows(
    squadRoles,
    (role) => role.person_id,
    "current squad assignment",
  );
  const personIds = [...squadRoleByPersonId.keys()];

  const [
    peopleResult,
    profilesResult,
    contractsResult,
    numbersResult,
    squadNumberHistoryResult,
  ] =
    await Promise.all([
      supabase
        .from("public_people")
        .select("id, slug, display_name")
        .in("id", personIds),
      supabase
        .from("player_profiles")
        .select(
          "person_id, nationality, date_of_birth, height_cm, primary_position, position_group, summary, source_id",
        )
        .in("person_id", personIds),
      supabase
        .from("current_public_role_assignments")
        .select("person_id, valid_from, valid_to")
        .eq("club_id", club.id)
        .eq("role_type", "player")
        .eq("assignment_type", "contracted")
        .in("person_id", personIds),
      supabase
        .from("current_public_squad_numbers")
        .select("person_id, squad_number, valid_from, valid_to")
        .eq("team_id", team.id)
        .in("person_id", personIds),
      supabase
        .from("squad_number_history")
        .select(
          "person_id, squad_number, valid_from, valid_to, change_type, source_id",
        )
        .eq("team_id", team.id)
        .eq("visibility", "public")
        .is("superseded_at", null)
        .in("person_id", personIds)
        .order("valid_from", { ascending: true }),
    ]);

  throwOnSupabaseError("public people", peopleResult.error);
  throwOnSupabaseError("public player profiles", profilesResult.error);
  throwOnSupabaseError("public player contracts", contractsResult.error);
  throwOnSupabaseError("current public squad numbers", numbersResult.error);
  throwOnSupabaseError(
    "public squad number history",
    squadNumberHistoryResult.error,
  );

  const people = peopleResult.data as PersonRow[];
  const profiles = profilesResult.data as ProfileRow[];
  const contracts = contractsResult.data as RoleRow[];
  const squadNumbers = numbersResult.data as SquadNumberRow[];
  const squadNumberHistory =
    squadNumberHistoryResult.data as SquadNumberHistoryRow[];
  const personById = indexUniqueRows(people, (person) => person.id, "person row");
  const profileByPersonId = indexUniqueRows(
    profiles,
    (profile) => profile.person_id,
    "profile row",
  );
  const contractByPersonId = indexUniqueRows(
    contracts,
    (contract) => contract.person_id,
    "current contract assignment",
  );
  const squadNumberByPersonId = indexUniqueRows(
    squadNumbers,
    (number) => number.person_id,
    "current squad number",
  );

  const sourceIds = [
    ...profiles.map((profile) =>
      requireText(profile.source_id, "profile source", profile.person_id),
    ),
    ...squadNumberHistory.map((history) =>
      requireText(history.source_id, "squad number source", history.person_id),
    ),
  ];
  const { data: sourceData, error: sourceError } = await supabase
    .from("sources")
    .select("id, url, publisher, retrieved_at")
    .eq("visibility", "public")
    .in("id", [...new Set(sourceIds)]);
  throwOnSupabaseError("public player sources", sourceError);

  const sourceById = indexUniqueRows(
    sourceData as SourceRow[],
    (source) => source.id,
    "source row",
  );
  const squadNumberHistoryByPersonId = createSquadNumberHistoryByPersonId(
    squadNumberHistory,
    squadNumbers,
    sourceById,
  );

  const players = personIds.map((personId): Player => {
    const person = personById.get(personId);
    const profile = profileByPersonId.get(personId);
    const squadRole = squadRoleByPersonId.get(personId);

    if (!person || !profile || !squadRole) {
      throw new Error(`Incomplete required public player data for ${personId}`);
    }

    const sourceId = requireText(profile.source_id, "profile source", personId);
    const source = sourceById.get(sourceId);

    if (!source) {
      throw new Error(`Missing public profile source row for ${personId}`);
    }

    const name = requireText(person.display_name, "display name", personId);

    return {
      slug: requireText(person.slug, "slug", personId),
      name,
      initials: createInitials(name),
      position: requireText(profile.primary_position, "position", personId),
      positionGroup: requireText(
        profile.position_group,
        "position group",
        personId,
      ) as PositionGroup,
      nationality: toJapaneseNationality(profile.nationality, personId),
      squadNumber: squadNumberByPersonId.get(personId)?.squad_number ?? null,
      dateOfBirth: profile.date_of_birth,
      heightCm: profile.height_cm,
      joinedAt: squadRole.valid_from,
      contractUntil: contractByPersonId.get(personId)?.valid_to ?? null,
      summary: profile.summary?.trim() || null,
      squadNumberHistory: squadNumberHistoryByPersonId.get(personId) ?? [],
      sourceUrl: requireText(source.url, "profile source URL", personId),
      checkedAt: toCheckedAt(
        source.retrieved_at,
        `public player ${personId} profile`,
      ),
    };
  });

  return players.sort((left, right) => left.slug.localeCompare(right.slug));
});

export async function getPlayers() {
  return loadPlayers();
}

export async function getPlayerBySlug(slug: string) {
  const players = await getPlayers();
  return players.find((player) => player.slug === slug);
}

export async function getPlayerSlugs() {
  const players = await getPlayers();
  return players.map((player) => player.slug);
}
