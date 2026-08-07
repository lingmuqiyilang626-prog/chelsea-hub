import "server-only";

import { cache } from "react";

import { createServerSupabaseClient } from "@/lib/supabase/server";

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
  retrieved_at: string | null;
  url: string;
};

type SquadNumberRow = {
  person_id: string;
  squad_number: number;
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

function toCheckedAt(retrievedAt: string | null, personId: string) {
  if (!retrievedAt) {
    throw new Error(`Missing profile source retrieved_at for public player ${personId}`);
  }

  const checkedAt = retrievedAt.slice(0, 10);

  if (!/^\d{4}-\d{2}-\d{2}$/.test(checkedAt)) {
    throw new Error(`Invalid profile source retrieved_at for public player ${personId}`);
  }

  return checkedAt;
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
    .from("role_assignments")
    .select("person_id, valid_from, valid_to")
    .eq("club_id", club.id)
    .eq("team_id", team.id)
    .eq("role_type", "player")
    .eq("assignment_type", "squad")
    .is("superseded_at", null);
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

  const [peopleResult, profilesResult, contractsResult, numbersResult] =
    await Promise.all([
      supabase
        .from("public_people")
        .select("id, slug, display_name")
        .in("id", personIds),
      supabase
        .from("player_profiles")
        .select(
          "person_id, nationality, date_of_birth, height_cm, primary_position, summary, source_id",
        )
        .in("person_id", personIds),
      supabase
        .from("role_assignments")
        .select("person_id, valid_from, valid_to")
        .eq("club_id", club.id)
        .eq("role_type", "player")
        .eq("assignment_type", "contracted")
        .is("superseded_at", null)
        .in("person_id", personIds),
      supabase
        .from("current_public_squad_numbers")
        .select("person_id, squad_number")
        .eq("team_id", team.id)
        .in("person_id", personIds),
    ]);

  throwOnSupabaseError("public people", peopleResult.error);
  throwOnSupabaseError("public player profiles", profilesResult.error);
  throwOnSupabaseError("public player contracts", contractsResult.error);
  throwOnSupabaseError("current public squad numbers", numbersResult.error);

  const people = peopleResult.data as PersonRow[];
  const profiles = profilesResult.data as ProfileRow[];
  const contracts = contractsResult.data as RoleRow[];
  const squadNumbers = numbersResult.data as SquadNumberRow[];
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

  const sourceIds = profiles.map((profile) =>
    requireText(profile.source_id, "profile source", profile.person_id),
  );
  const { data: sourceData, error: sourceError } = await supabase
    .from("sources")
    .select("id, url, retrieved_at")
    .in("id", sourceIds);
  throwOnSupabaseError("public profile sources", sourceError);

  const sourceById = indexUniqueRows(
    sourceData as SourceRow[],
    (source) => source.id,
    "profile source row",
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
      nationality: requireText(profile.nationality, "nationality", personId),
      squadNumber: squadNumberByPersonId.get(personId)?.squad_number ?? null,
      dateOfBirth: profile.date_of_birth,
      heightCm: profile.height_cm,
      joinedAt: squadRole.valid_from,
      contractUntil: contractByPersonId.get(personId)?.valid_to ?? null,
      summary: requireText(profile.summary, "summary", personId),
      sourceUrl: requireText(source.url, "profile source URL", personId),
      checkedAt: toCheckedAt(source.retrieved_at, personId),
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
