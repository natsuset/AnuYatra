// Rule-based Quick Match astrology compatibility scorer.
// Inputs are intentionally lightweight (rashi + nakshatra + manglik + gotra).

class AstrologyDetails {
  final String? rashi;
  final String? nakshatra;
  final String? manglikStatus;
  final String? gotra;

  const AstrologyDetails({
    this.rashi,
    this.nakshatra,
    this.manglikStatus,
    this.gotra,
  });

  bool get hasAnyData =>
      (rashi?.trim().isNotEmpty ?? false) ||
      (nakshatra?.trim().isNotEmpty ?? false) ||
      (manglikStatus?.trim().isNotEmpty ?? false);
}

enum MatchVerdict { excellent, good, caution, incompatible, unknown }

class KootaResult {
  final String name;
  final MatchVerdict verdict;
  final int pointsEarned;
  final int pointsMax;
  final String shortReason;
  final String detailedExplainer;

  const KootaResult({
    required this.name,
    required this.verdict,
    required this.pointsEarned,
    required this.pointsMax,
    required this.shortReason,
    required this.detailedExplainer,
  });
}

class CompatibilityResult {
  final double overallPercent;
  final MatchVerdict overallVerdict;
  final List<KootaResult> kootas;
  final List<String> warnings;
  final bool hasEnoughData;

  const CompatibilityResult({
    required this.overallPercent,
    required this.overallVerdict,
    required this.kootas,
    required this.warnings,
    required this.hasEnoughData,
  });
}

const List<String> _rashiOrder = [
  'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
  'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces',
];

const Map<String, List<String>> _rashiAliases = {
  'aries': ['mesha', 'mesh'],
  'taurus': ['vrishabha', 'vrishabh', 'vrushabha'],
  'gemini': ['mithuna', 'mithun'],
  'cancer': ['karka', 'kark', 'karkata'],
  'leo': ['simha', 'sinh'],
  'virgo': ['kanya'],
  'libra': ['tula', 'thula'],
  'scorpio': ['vrischika', 'vruschika', 'vrishchika'],
  'sagittarius': ['dhanu', 'dhanus'],
  'capricorn': ['makara', 'makar'],
  'aquarius': ['kumbha', 'kumbh'],
  'pisces': ['meena', 'meen'],
};

int? _normalizeRashi(String? raw) {
  if (raw == null) return null;
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) return null;
  final direct = _rashiOrder.indexOf(key);
  if (direct >= 0) return direct;
  for (final entry in _rashiAliases.entries) {
    if (entry.value.contains(key)) {
      return _rashiOrder.indexOf(entry.key);
    }
  }
  return null;
}

const List<String> _nakshatraOrder = [
  'ashwini', 'bharani', 'krittika', 'rohini', 'mrigashira', 'ardra',
  'punarvasu', 'pushya', 'ashlesha', 'magha', 'purva phalguni',
  'uttara phalguni', 'hasta', 'chitra', 'swati', 'vishakha', 'anuradha',
  'jyeshtha', 'mula', 'purva ashadha', 'uttara ashadha', 'shravana',
  'dhanishta', 'shatabhisha', 'purva bhadrapada', 'uttara bhadrapada', 'revati',
];

int? _normalizeNakshatra(String? raw) {
  if (raw == null) return null;
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) return null;
  final direct = _nakshatraOrder.indexOf(key);
  if (direct >= 0) return direct;
  for (var i = 0; i < _nakshatraOrder.length; i++) {
    if (_nakshatraOrder[i].startsWith(key) ||
        key.startsWith(_nakshatraOrder[i])) {
      return i;
    }
  }
  return null;
}

enum _ManglikState { manglik, partial, nonManglik, unknown }

_ManglikState _normalizeManglik(String? raw) {
  if (raw == null) return _ManglikState.unknown;
  final key = raw.trim().toLowerCase();
  if (key.isEmpty || key == 'unknown' || key == 'not sure') {
    return _ManglikState.unknown;
  }
  if (key.contains('non') || key == 'no') return _ManglikState.nonManglik;
  if (key.contains('partial') || key.contains('anshik')) {
    return _ManglikState.partial;
  }
  if (key == 'yes' || key.contains('manglik') || key.contains('mangal')) {
    return _ManglikState.manglik;
  }
  return _ManglikState.unknown;
}

KootaResult _rashiKoota(AstrologyDetails a, AstrologyDetails b) {
  const max = 8;
  final ra = _normalizeRashi(a.rashi);
  final rb = _normalizeRashi(b.rashi);
  if (ra == null || rb == null) {
    return KootaResult(
      name: 'Rashi (Moon Sign)',
      verdict: MatchVerdict.unknown,
      pointsEarned: 0,
      pointsMax: max,
      shortReason: 'Rashi not provided on one or both profiles',
      detailedExplainer:
          'Rashi (moon sign) compatibility checks the relationship between '
          'the two moon signs. Without both rashi values this score cannot be computed.',
    );
  }
  final diff = ((rb - ra) % 12 + 12) % 12;
  int score;
  MatchVerdict verdict;
  String reason;
  if (diff == 0) {
    score = max;
    verdict = MatchVerdict.excellent;
    reason = 'Same rashi — strong moon-sign affinity';
  } else if ([4, 8].contains(diff)) {
    score = (max * 0.85).round();
    verdict = MatchVerdict.excellent;
    reason = 'Trine relationship — auspicious moon-sign pairing';
  } else if ([2, 10].contains(diff)) {
    score = (max * 0.65).round();
    verdict = MatchVerdict.good;
    reason = 'Sextile relationship — generally harmonious';
  } else if ([5, 9].contains(diff)) {
    score = (max * 0.40).round();
    verdict = MatchVerdict.caution;
    reason = '6/8 axis — needs careful consideration';
  } else if ([1, 11].contains(diff)) {
    score = (max * 0.30).round();
    verdict = MatchVerdict.caution;
    reason = '2/12 axis — financial / lifestyle differences possible';
  } else {
    score = (max * 0.55).round();
    verdict = MatchVerdict.good;
    reason = 'Neutral relationship — workable';
  }
  return KootaResult(
    name: 'Rashi (Moon Sign)',
    verdict: verdict,
    pointsEarned: score,
    pointsMax: max,
    shortReason: reason,
    detailedExplainer:
        'Moon-sign relationship reflects emotional rapport. Trines (5 signs apart) and '
        'identical signs are considered most supportive. The 2/12 and 6/8 axes are '
        'traditionally flagged for closer scrutiny.',
  );
}

KootaResult _nakshatraKoota(AstrologyDetails a, AstrologyDetails b) {
  const max = 6;
  final na = _normalizeNakshatra(a.nakshatra);
  final nb = _normalizeNakshatra(b.nakshatra);
  if (na == null || nb == null) {
    return KootaResult(
      name: 'Nakshatra (Birth Star)',
      verdict: MatchVerdict.unknown,
      pointsEarned: 0,
      pointsMax: max,
      shortReason: 'Nakshatra not provided on one or both profiles',
      detailedExplainer:
          'Nakshatra (birth star) is used in traditional Tara koota to assess '
          'wellbeing compatibility. Both birth stars are needed for this check.',
    );
  }
  final tara = ((nb - na) % 9 + 9) % 9;
  const bad = {2, 4, 6};
  const exc = {0, 3, 5};
  int score;
  MatchVerdict verdict;
  String reason;
  if (exc.contains(tara)) {
    score = max;
    verdict = MatchVerdict.excellent;
    reason = 'Tara position is auspicious (${tara + 1}th)';
  } else if (bad.contains(tara)) {
    score = (max * 0.30).round();
    verdict = MatchVerdict.caution;
    reason = 'Tara position is challenging (${tara + 1}th)';
  } else {
    score = (max * 0.65).round();
    verdict = MatchVerdict.good;
    reason = 'Tara position is neutral (${tara + 1}th)';
  }
  if (na == nb) {
    score = max;
    verdict = MatchVerdict.excellent;
    reason = 'Same nakshatra — strong star alignment';
  }
  return KootaResult(
    name: 'Nakshatra (Birth Star)',
    verdict: verdict,
    pointsEarned: score,
    pointsMax: max,
    shortReason: reason,
    detailedExplainer:
        'Tara koota counts from one nakshatra to the other. Positions 1, 4 and 6 (Janma, '
        'Kshema and Saadhaka) are considered favourable, while 3, 5 and 7 (Vipat, Pratyak '
        'and Vadha) traditionally need parihara (remedy).',
  );
}

KootaResult _manglikKoota(AstrologyDetails a, AstrologyDetails b) {
  const max = 4;
  final ma = _normalizeManglik(a.manglikStatus);
  final mb = _normalizeManglik(b.manglikStatus);
  if (ma == _ManglikState.unknown || mb == _ManglikState.unknown) {
    return KootaResult(
      name: 'Manglik Dosha',
      verdict: MatchVerdict.unknown,
      pointsEarned: 0,
      pointsMax: max,
      shortReason: 'Manglik status not confirmed on one or both profiles',
      detailedExplainer:
          'Manglik dosha is determined by Mars\' placement in specific houses. Tradition '
          'recommends matching either both manglik or both non-manglik.',
    );
  }
  if (ma == mb) {
    return KootaResult(
      name: 'Manglik Dosha',
      verdict: MatchVerdict.excellent,
      pointsEarned: max,
      pointsMax: max,
      shortReason: ma == _ManglikState.manglik
          ? 'Both manglik — neutralises the dosha'
          : 'Neither manglik — no dosha to manage',
      detailedExplainer:
          'When both partners share the same manglik status, the traditional dosha is '
          'considered cancelled. This is a strong positive in Indian matching tradition.',
    );
  }
  if (ma == _ManglikState.partial || mb == _ManglikState.partial) {
    return KootaResult(
      name: 'Manglik Dosha',
      verdict: MatchVerdict.good,
      pointsEarned: (max * 0.65).round(),
      pointsMax: max,
      shortReason: 'Partial manglik — usually compatible',
      detailedExplainer:
          'A partial (anshik) manglik is generally considered compatible with either side. '
          'Family astrologer consult is still advised before finalising.',
    );
  }
  return KootaResult(
    name: 'Manglik Dosha',
    verdict: MatchVerdict.caution,
    pointsEarned: 0,
    pointsMax: max,
    shortReason: 'Manglik mismatch — traditional remedy advised',
    detailedExplainer:
        'A manglik / non-manglik pairing is traditionally flagged for closer review. Many '
        'families accept the pairing after consulting their astrologer; some seek a parihara '
        '(remedy) such as Kumbh Vivah.',
  );
}

KootaResult _gotraKoota(AstrologyDetails a, AstrologyDetails b) {
  const max = 2;
  final ga = a.gotra?.trim().toLowerCase();
  final gb = b.gotra?.trim().toLowerCase();
  if (ga == null || gb == null || ga.isEmpty || gb.isEmpty) {
    return KootaResult(
      name: 'Gotra',
      verdict: MatchVerdict.unknown,
      pointsEarned: 0,
      pointsMax: max,
      shortReason: 'Gotra not provided on one or both profiles',
      detailedExplainer:
          'Same-gotra marriages are traditionally avoided in many communities. '
          'Provide gotra on both profiles for this check.',
    );
  }
  if (ga == gb) {
    return KootaResult(
      name: 'Gotra',
      verdict: MatchVerdict.incompatible,
      pointsEarned: 0,
      pointsMax: max,
      shortReason: 'Same gotra — traditionally avoided',
      detailedExplainer:
          'Most Indian communities discourage marriage within the same gotra (paternal '
          'lineage). Confirm with your family elders before proceeding.',
    );
  }
  return KootaResult(
    name: 'Gotra',
    verdict: MatchVerdict.excellent,
    pointsEarned: max,
    pointsMax: max,
    shortReason: 'Different gotras — clear',
    detailedExplainer:
        'Different paternal lineages — meets the customary requirement followed by most communities.',
  );
}

MatchVerdict _verdictFor(double pct, {bool hardFail = false}) {
  if (hardFail) return MatchVerdict.incompatible;
  if (pct >= 0.75) return MatchVerdict.excellent;
  if (pct >= 0.55) return MatchVerdict.good;
  if (pct >= 0.35) return MatchVerdict.caution;
  return MatchVerdict.incompatible;
}

CompatibilityResult matchAstrology(
  AstrologyDetails a,
  AstrologyDetails b,
) {
  final kootas = <KootaResult>[
    _rashiKoota(a, b),
    _nakshatraKoota(a, b),
    _manglikKoota(a, b),
    _gotraKoota(a, b),
  ];

  final scored = kootas.where((k) => k.verdict != MatchVerdict.unknown).toList();
  final earned = scored.fold<int>(0, (sum, k) => sum + k.pointsEarned);
  final maxScore = scored.fold<int>(0, (sum, k) => sum + k.pointsMax);
  final ratio = maxScore == 0 ? 0.0 : earned / maxScore;
  final hardFail = kootas.any(
    (k) => k.name == 'Gotra' && k.verdict == MatchVerdict.incompatible,
  );

  final warnings = <String>[];
  final unknownCount = kootas.length - scored.length;
  if (unknownCount > 0) {
    warnings.add(
      '$unknownCount of ${kootas.length} factors could not be evaluated — provide missing details for a better match.',
    );
  }
  if (hardFail) {
    warnings.add('Same gotra detected — traditionally a hard stop.');
  }

  return CompatibilityResult(
    overallPercent: ratio * 100,
    overallVerdict: _verdictFor(ratio, hardFail: hardFail),
    kootas: kootas,
    warnings: warnings,
    hasEnoughData: scored.length >= 2,
  );
}
