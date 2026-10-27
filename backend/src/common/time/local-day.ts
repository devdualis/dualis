/** Local calendar day (YYYY-MM-DD) for a device offset in minutes east of UTC. */
export function localDay(date: Date, tzOffsetMinutes = 0): string {
  return new Date(date.getTime() + tzOffsetMinutes * 60_000).toISOString().slice(0, 10);
}
