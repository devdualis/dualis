/// Minutes east of UTC for the device clock (e.g. -180 for Brasília).
int localTzOffsetMinutes([DateTime? now]) =>
    (now ?? DateTime.now()).timeZoneOffset.inMinutes;
