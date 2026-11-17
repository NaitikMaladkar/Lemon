import 'package:flutter/material.dart';

import '../theme.dart';
import 'lemon_logo.dart';

/// Citrus gradient header used at the top of every tab.
class LemonHeader extends StatelessWidget {
  const LemonHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const <Widget>[],
    this.showLogo = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? <Color>[const Color(0xFF3A3218), const Color(0xFF221F10)]
              : <Color>[LemonPalette.citrus, LemonPalette.citrusDeep],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: LemonPalette.citrusDeep.withOpacity(dark ? 0.18 : 0.32),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(dark ? 0.05 : 0.16),
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: -60,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(dark ? 0.04 : 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
              child: Row(
                children: <Widget>[
                  if (showLogo) ...<Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(dark ? 0.10 : 0.92),
                      ),
                      alignment: Alignment.center,
                      child: const LemonLogo(size: 30),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: dark ? LemonPalette.nightInk : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: (dark ? LemonPalette.nightInk : Colors.white)
                                .withOpacity(0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round translucent button that sits inside the header gradient.
class HeaderAction extends StatelessWidget {
  const HeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Widget button = Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: Colors.white.withOpacity(dark ? 0.10 : 0.22),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 20,
              color: dark ? LemonPalette.nightInk : Colors.white,
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
