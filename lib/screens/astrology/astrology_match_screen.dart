import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:testing_flutter/core/constants/app_spacing.dart';
import 'package:testing_flutter/core/services/astrology_matcher.dart';
import 'package:testing_flutter/core/theme/app_palette.dart';

class AstrologyMatchScreen extends StatelessWidget {
  const AstrologyMatchScreen({
    super.key,
    required this.subject,
    required this.candidate,
    required this.subjectLabel,
    required this.candidateLabel,
    this.onEditDetails,
  });

  final AstrologyDetails subject;
  final AstrologyDetails candidate;
  final String subjectLabel;
  final String candidateLabel;
  final VoidCallback? onEditDetails;

  @override
  Widget build(BuildContext context) {
    final result = matchAstrology(subject, candidate);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Astrology Match'),
        actions: [
          if (onEditDetails != null)
            IconButton(
              tooltip: 'Edit details',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEditDetails,
            ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.allMd,
        children: [
          _ScoreGauge(result: result),
          AppSpacing.gapH16,
          _PairHeader(
            subjectLabel: subjectLabel,
            candidateLabel: candidateLabel,
            subject: subject,
            candidate: candidate,
          ),
          AppSpacing.gapH16,
          _QuickMatchCaveat(),
          AppSpacing.gapH16,
          if (result.warnings.isNotEmpty) ...[
            ...result.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _WarningBanner(message: w),
              ),
            ),
            AppSpacing.gapH8,
          ],
          Text(
            'Per-factor breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          AppSpacing.gapH8,
          ...result.kootas.map((k) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _KootaCard(koota: k),
              )),
          AppSpacing.gapH24,
        ],
      ),
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({required this.result});
  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(context, result.overallVerdict);
    final label = _verdictLabel(result.overallVerdict);
    final scheme = Theme.of(context).colorScheme;
    final hasData = result.hasEnoughData;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _GaugePainter(
                      value: hasData ? result.overallPercent / 100.0 : 0,
                      color: color,
                      background: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasData ? '${result.overallPercent.round()}' : '—',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'out of 100',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.color,
    required this.background,
  });
  final double value;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 14.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = background;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, bgPaint);
    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color || old.background != background;
}

class _PairHeader extends StatelessWidget {
  const _PairHeader({
    required this.subjectLabel,
    required this.candidateLabel,
    required this.subject,
    required this.candidate,
  });
  final String subjectLabel;
  final String candidateLabel;
  final AstrologyDetails subject;
  final AstrologyDetails candidate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: _PartyColumn(label: subjectLabel, details: subject)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Icon(Icons.compare_arrows_rounded,
                    color: scheme.primary, size: 20),
                const SizedBox(height: 4),
                Text('vs',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
          Expanded(child: _PartyColumn(label: candidateLabel, details: candidate)),
        ],
      ),
    );
  }
}

class _PartyColumn extends StatelessWidget {
  const _PartyColumn({required this.label, required this.details});
  final String label;
  final AstrologyDetails details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget row(String k, String? v) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  k,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  (v == null || v.trim().isEmpty) ? '—' : v,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        row('Rashi', details.rashi),
        row('Nakshatra', details.nakshatra),
        row('Manglik', details.manglikStatus),
        row('Gotra', details.gotra),
      ],
    );
  }
}

class _QuickMatchCaveat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.info.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: context.palette.info.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: context.palette.info),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              'Quick Match — based on rashi, nakshatra, manglik and gotra only. '
              'This is indicative, not a full Ashtakoot Milan. Consult your astrologer for a complete reading.',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.palette.warning.withValues(alpha: 0.10),
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: context.palette.warning.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: context.palette.warning),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KootaCard extends StatefulWidget {
  const _KootaCard({required this.koota});
  final KootaResult koota;

  @override
  State<_KootaCard> createState() => _KootaCardState();
}

class _KootaCardState extends State<_KootaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final k = widget.koota;
    final color = _verdictColor(context, k.verdict);
    final maxLabel = k.verdict == MatchVerdict.unknown
        ? '—'
        : '${k.pointsEarned}/${k.pointsMax}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: AppSpacing.roundedLg,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _verdictIcon(k.verdict),
                      size: 18,
                      color: color,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          k.shortReason,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapW8,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        maxLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  k.detailedExplainer,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _verdictColor(BuildContext context, MatchVerdict v) {
  switch (v) {
    case MatchVerdict.excellent:
      return context.palette.success;
    case MatchVerdict.good:
      return context.palette.info;
    case MatchVerdict.caution:
      return context.palette.warning;
    case MatchVerdict.incompatible:
      return context.palette.error;
    case MatchVerdict.unknown:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

String _verdictLabel(MatchVerdict v) {
  switch (v) {
    case MatchVerdict.excellent:
      return 'Excellent match';
    case MatchVerdict.good:
      return 'Good match';
    case MatchVerdict.caution:
      return 'Proceed with care';
    case MatchVerdict.incompatible:
      return 'Not recommended';
    case MatchVerdict.unknown:
      return 'Not enough data';
  }
}

IconData _verdictIcon(MatchVerdict v) {
  switch (v) {
    case MatchVerdict.excellent:
      return Icons.check_circle_rounded;
    case MatchVerdict.good:
      return Icons.thumb_up_alt_outlined;
    case MatchVerdict.caution:
      return Icons.warning_amber_rounded;
    case MatchVerdict.incompatible:
      return Icons.do_not_disturb_alt_rounded;
    case MatchVerdict.unknown:
      return Icons.help_outline_rounded;
  }
}
