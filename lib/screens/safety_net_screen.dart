import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/frosted_glass_card.dart';

/// Safety Net Screen — crisis resources, affirmations, and trusted contacts.
class SafetyNetScreen extends StatefulWidget {
  const SafetyNetScreen({super.key});

  @override
  State<SafetyNetScreen> createState() => _SafetyNetScreenState();
}

class _SafetyNetScreenState extends State<SafetyNetScreen> {
  int _revealedAffirmationIndex = -1;

  static const List<String> _affirmations = [
    'This feeling is temporary. It will pass.',
    "I've survived difficult moments before.",
    "I deserve support and it's okay to ask for help.",
    'Right now, I am safe.',
    'I am stronger than I think.',
    'It is okay to not be okay.',
    'I am worthy of love and kindness.',
    'One breath at a time. One moment at a time.',
    'My feelings are valid, but they do not define me.',
    'I choose to be gentle with myself today.',
  ];

  static const List<_HotlineRegion> _regions = [
    _HotlineRegion(
      name: 'India',
      icon: '🇮🇳',
      hotlines: [
        _Hotline('iCall', '9152987821'),
        _Hotline('Vandrevala Foundation', '18602662345'),
        _Hotline('AASRA', '912227546669'),
      ],
    ),
    _HotlineRegion(
      name: 'United States',
      icon: '🇺🇸',
      hotlines: [
        _Hotline('988 Suicide & Crisis Lifeline', '988'),
        _Hotline('Crisis Text Line', 'text HOME to 741741', isText: true),
      ],
    ),
    _HotlineRegion(
      name: 'United Kingdom',
      icon: '🇬🇧',
      hotlines: [
        _Hotline('Samaritans', '116123'),
        _Hotline('SHOUT', 'text SHOUT to 85258', isText: true),
      ],
    ),
    _HotlineRegion(
      name: 'International',
      icon: '🌍',
      hotlines: [
        _Hotline('Befrienders Worldwide', 'befrienders.org', isWebsite: true),
      ],
    ),
  ];

  Future<void> _launchDialer(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse('https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _revealNextAffirmation() {
    if (_revealedAffirmationIndex < _affirmations.length - 1) {
      setState(() => _revealedAffirmationIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.bgGradient(context),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  children: [
                    _buildHero(),
                    const SizedBox(height: 28),
                    _buildHotlinesSection(),
                    const SizedBox(height: 28),
                    _buildAffirmationsSection(),
                    const SizedBox(height: 28),
                    _buildTrustedContactSection(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.dividerColor(context),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.secondary(context),
                size: 20,
              ),
            ),
          ),
          Text(
            'Safety Net',
            style: AppTypography.uiLabelC(context),
          ),
          const SizedBox(width: 42),
        ],
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 500),
          curve: AppTheme.gentleCurve,
        );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Icon(
          Icons.favorite_rounded,
          color: AppColors.coralDa5e5a.withValues(alpha: 0.7),
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          "You're not alone",
          style: AppTypography.heroHeadingC(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Help is always within reach.',
          style: AppTypography.subtitleC(context),
          textAlign: TextAlign.center,
        ),
      ],
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 600),
          curve: AppTheme.gentleCurve,
        )
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildHotlinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Hotlines',
          style: AppTypography.sectionHeadingC(context),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a number to call',
          style: AppTypography.captionC(context),
        ),
        const SizedBox(height: 16),
        ..._regions.asMap().entries.map((entry) {
          final index = entry.key;
          final region = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRegionCard(region).animate().fadeIn(
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 500),
                  curve: AppTheme.gentleCurve,
                ),
          );
        }),
      ],
    );
  }

  Widget _buildRegionCard(_HotlineRegion region) {
    return FrostedGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${region.icon}  ${region.name}',
            style: AppTypography.subtitleC(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...region.hotlines.map((hotline) => _buildHotlineTile(hotline)),
        ],
      ),
    );
  }

  Widget _buildHotlineTile(_Hotline hotline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: hotline.isText
            ? null
            : hotline.isWebsite
                ? () => _launchUrl(hotline.number)
                : () => _launchDialer(hotline.number),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.coralDa5e5a.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hotline.isText
                    ? Icons.textsms_rounded
                    : hotline.isWebsite
                        ? Icons.language_rounded
                        : Icons.phone_rounded,
                color: AppColors.coralDa5e5a,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotline.name,
                    style: AppTypography.bodyC(context).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    hotline.number,
                    style: AppTypography.captionC(context).copyWith(
                          color: AppColors.coralDa5e5a,
                        ),
                  ),
                ],
              ),
            ),
            if (!hotline.isText)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.tertiary(context),
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffirmationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Positive Scripts',
          style: AppTypography.sectionHeadingC(context),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to reveal a calming affirmation',
          style: AppTypography.captionC(context),
        ),
        const SizedBox(height: 16),
        FrostedGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_revealedAffirmationIndex >= 0)
                ...List.generate(_revealedAffirmationIndex + 1, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.spa_rounded,
                          color: AppColors.sageGreen.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _affirmations[i],
                            style: AppTypography.emotionalTextC(context)
                                .copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 500),
                        curve: AppTheme.gentleCurve,
                      )
                      .slideY(begin: 0.05, end: 0);
                }),
              if (_revealedAffirmationIndex < _affirmations.length - 1)
                GestureDetector(
                  onTap: _revealNextAffirmation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.sageGreen.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusButton),
                      border: Border.all(
                        color: AppColors.sageGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _revealedAffirmationIndex < 0
                            ? 'Tap to reveal'
                            : 'Reveal another',
                        style: AppTypography.buttonText(
                          color: AppColors.sageGreen,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'You have all the strength you need.',
                    style: AppTypography.captionC(context),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustedContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trusted Contact',
          style: AppTypography.sectionHeadingC(context),
        ),
        const SizedBox(height: 16),
        FrostedGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.people_rounded,
                color: AppColors.softIndigo.withValues(alpha: 0.6),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Set up a trusted contact who can be notified when you need support',
                style: AppTypography.bodyC(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _launchDialer(''),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.softIndigo.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusButton),
                    border: Border.all(
                      color: AppColors.softIndigo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.contacts_rounded,
                          color: AppColors.softIndigo,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Open Contacts',
                          style: AppTypography.buttonText(
                            color: AppColors.softIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(
          delay: const Duration(milliseconds: 400),
          duration: const Duration(milliseconds: 500),
          curve: AppTheme.gentleCurve,
        );
  }

  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Remember: reaching out is a sign of strength.',
          style: AppTypography.emotionalTextC(context).copyWith(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    ).animate().fadeIn(
          delay: const Duration(milliseconds: 600),
          duration: const Duration(milliseconds: 500),
        );
  }
}

class _HotlineRegion {
  final String name;
  final String icon;
  final List<_Hotline> hotlines;

  const _HotlineRegion({
    required this.name,
    required this.icon,
    required this.hotlines,
  });
}

class _Hotline {
  final String name;
  final String number;
  final bool isText;
  final bool isWebsite;

  const _Hotline(this.name, this.number,
      {this.isText = false, this.isWebsite = false});
}
