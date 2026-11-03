/// Data areas a grantee may see (D2). The API values match
/// `SHARE_CATEGORIES` on the backend. Help requests are never shared.
enum ShareCategory {
  habits('habits'),
  physicalJournal('physical_journal'),
  emotionalJournal('emotional_journal'),
  conditions('conditions'),
  care('care');

  const ShareCategory(this.apiValue);
  final String apiValue;

  /// Pre-checked on a new invite: habits only. The emotional journal is
  /// never pre-checked.
  static const Set<ShareCategory> defaults = {ShareCategory.habits};

  static ShareCategory? parse(Object? raw) {
    for (final c in values) {
      if (c.apiValue == raw) return c;
    }
    return null;
  }

  /// Unknown values are ignored; result keeps the enum order, no duplicates.
  static List<ShareCategory> parseList(Object? raw) {
    if (raw is! List) return const [];
    final found = raw.map(parse).whereType<ShareCategory>().toSet();
    return [for (final c in values) if (found.contains(c)) c];
  }
}

/// Who the grantee is to the owner. Matches `GRANT_RELATIONSHIPS` on the
/// backend. Legacy grants have no relationship (null).
enum GrantRelationship {
  spousePartner('spouse_partner'),
  sibling('sibling'),
  parent('parent'),
  child('child'),
  otherFamily('other_family'),
  caregiver('caregiver'),
  friend('friend'),
  other('other');

  const GrantRelationship(this.apiValue);
  final String apiValue;

  static GrantRelationship? parse(Object? raw) {
    for (final r in values) {
      if (r.apiValue == raw) return r;
    }
    return null;
  }
}
