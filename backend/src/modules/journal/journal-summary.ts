import {
  EMOTIONAL_TIMES,
  PHYSICAL_REGIONS,
  TRIGGER_KEYS,
  isCustomOptionKey,
  optionKeyBranch,
  optionKeyRoot,
} from './constants/journal-keys.constant';
import { localDay } from '../../common/time/local-day';
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

export { localDay };

/** Marker of a trigger in `cooccurrence` (`trigger:sono`). */
export const TRIGGER_MARKER_PREFIX = 'trigger:';

/**
 * Markers compared for "seen on the same day" (contract, "Summary markers"):
 * a physical item gives its region (`cabeca`), an emotional item its time and branch
 * (`futuro.mente`, or the bare time `futuro` for a written item) and each trigger
 * `trigger:<key>`. The app resolves every marker to the person's own wording.
 */
export function dayMarkers(entry: SummaryEntryInput): string[] {
  const markers = new Set<string>();
  for (const item of entry.items) {
    if (!item.optionKey) continue;
    if (item.kind === 'physical') markers.add(optionKeyRoot(item.optionKey));
    if (item.kind === 'emotional') {
      markers.add(isCustomOptionKey(item.optionKey) ? optionKeyRoot(item.optionKey) : optionKeyBranch(item.optionKey));
    }
  }
  for (const trigger of entry.triggers) markers.add(`${TRIGGER_MARKER_PREFIX}${trigger}`);
  return [...markers];
}

/**
 * Counts over the person's own entries. Every count is the number of distinct local
 * days (device day from `tzOffsetMinutes`) on which the key was marked: two entries
 * with "Cabeça" on the same day count as 1 day. Descriptive only: no labels, no text,
 * no interpretation.
 */
export function buildJournalSummary(
  entries: SummaryEntryInput[],
  days: number,
  tzOffsetMinutes = 0,
): JournalSummaryDto {
  const daysByKey = {
    time: new Map<string, Set<string>>(),
    region: new Map<string, Set<string>>(),
    option: new Map<string, Set<string>>(),
    trigger: new Map<string, Set<string>>(),
  };
  const markersByDay = new Map<string, Set<string>>();
  const mark = (map: Map<string, Set<string>>, key: string, day: string) => {
    const set = map.get(key) ?? new Set<string>();
    set.add(day);
    map.set(key, set);
  };

  for (const entry of entries) {
    const day = localDay(entry.recordedAt, tzOffsetMinutes);
    for (const item of entry.items) {
      if (!item.optionKey) continue;
      mark(daysByKey.option, item.optionKey, day);
      if (item.kind === 'emotional') mark(daysByKey.time, optionKeyRoot(item.optionKey), day);
      if (item.kind === 'physical') mark(daysByKey.region, optionKeyRoot(item.optionKey), day);
    }
    for (const t of entry.triggers) mark(daysByKey.trigger, t, day);

    const dayMarkerSet = markersByDay.get(day) ?? new Set<string>();
    for (const m of dayMarkers(entry)) dayMarkerSet.add(m);
    markersByDay.set(day, dayMarkerSet);
  }

  const counted = (map: Map<string, Set<string>>, keys?: readonly string[]) => {
    const out: Record<string, number> = keys ? zeroed(keys) : {};
    for (const [key, daySet] of map) if (!keys || key in out) out[key] = daySet.size;
    return out;
  };
  const byTime = counted(daysByKey.time, EMOTIONAL_TIMES);
  const byRegion = counted(daysByKey.region, PHYSICAL_REGIONS);
  const byTrigger = counted(daysByKey.trigger, TRIGGER_KEYS);
  const byOptionKey = counted(daysByKey.option);
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
