import {
  EMOTIONAL_TIMES,
  PHYSICAL_REGIONS,
  TRIGGER_KEYS,
  optionKeyRoot,
} from './constants/journal-keys.constant';
import { JournalSummaryDto } from './dto/journal.dto';

export interface SummaryEntryInput {
  recordedAt: Date;
  triggers: string[];
  items: Array<{ kind: string; optionKey: string | null }>;
}

/** Pairs shown in the summary: seen together on at least this many days. */
export const COOCCURRENCE_MIN_DAYS = 2;
export const COOCCURRENCE_MAX_PAIRS = 20;

const zeroed = (keys: readonly string[]) => Object.fromEntries(keys.map((k) => [k, 0])) as Record<string, number>;

/** Local calendar day (YYYY-MM-DD) for a device offset in minutes east of UTC. */
export function localDay(date: Date, tzOffsetMinutes = 0): string {
  return new Date(date.getTime() + tzOffsetMinutes * 60_000).toISOString().slice(0, 10);
}

/**
 * Markers compared for "seen on the same day": the region (physical), the time and
 * branch (emotional, e.g. `futuro.mente`) and each trigger (`trigger.sono`).
 */
function dayMarkers(entry: SummaryEntryInput): string[] {
  const markers = new Set<string>();
  for (const item of entry.items) {
    if (!item.optionKey) continue;
    if (item.kind === 'physical') markers.add(optionKeyRoot(item.optionKey));
    if (item.kind === 'emotional') markers.add(item.optionKey.split('.').slice(0, 2).join('.'));
  }
  for (const trigger of entry.triggers) markers.add(`trigger.${trigger}`);
  return [...markers];
}

/**
 * Counts over the person's own entries. Each count is the number of entries that
 * contain the key (an entry with two head items counts once for `cabeca`).
 * Descriptive only: no labels, no text, no interpretation.
 */
export function buildJournalSummary(
  entries: SummaryEntryInput[],
  days: number,
  tzOffsetMinutes = 0,
): JournalSummaryDto {
  const byTime = zeroed(EMOTIONAL_TIMES);
  const byRegion = zeroed(PHYSICAL_REGIONS);
  const byTrigger = zeroed(TRIGGER_KEYS);
  const byOptionKey: Record<string, number> = {};
  const markersByDay = new Map<string, Set<string>>();

  for (const entry of entries) {
    const times = new Set<string>();
    const regions = new Set<string>();
    const optionKeys = new Set<string>();
    for (const item of entry.items) {
      if (!item.optionKey) continue;
      optionKeys.add(item.optionKey);
      if (item.kind === 'emotional') times.add(optionKeyRoot(item.optionKey));
      if (item.kind === 'physical') regions.add(optionKeyRoot(item.optionKey));
    }
    for (const t of times) if (t in byTime) byTime[t] += 1;
    for (const r of regions) if (r in byRegion) byRegion[r] += 1;
    for (const k of optionKeys) byOptionKey[k] = (byOptionKey[k] ?? 0) + 1;
    for (const t of new Set(entry.triggers)) if (t in byTrigger) byTrigger[t] += 1;

    const day = localDay(entry.recordedAt, tzOffsetMinutes);
    const dayMarkerSet = markersByDay.get(day) ?? new Set<string>();
    for (const m of dayMarkers(entry)) dayMarkerSet.add(m);
    markersByDay.set(day, dayMarkerSet);
  }

  const pairDays = new Map<string, number>();
  for (const markers of markersByDay.values()) {
    const sorted = [...markers].sort();
    for (let i = 0; i < sorted.length; i++) {
      for (let j = i + 1; j < sorted.length; j++) {
        const key = `${sorted[i]}|${sorted[j]}`;
        pairDays.set(key, (pairDays.get(key) ?? 0) + 1);
      }
    }
  }

  const cooccurrence = [...pairDays.entries()]
    .filter(([, n]) => n >= COOCCURRENCE_MIN_DAYS)
    .map(([key, n]) => {
      const [a, b] = key.split('|');
      return { a, b, days: n };
    })
    .sort((x, y) => y.days - x.days || x.a.localeCompare(y.a) || x.b.localeCompare(y.b))
    .slice(0, COOCCURRENCE_MAX_PAIRS);

  return {
    days,
    totalEntries: entries.length,
    daysWithEntries: markersByDay.size,
    byTime,
    byRegion,
    byOptionKey,
    byTrigger,
    cooccurrence,
  };
}
