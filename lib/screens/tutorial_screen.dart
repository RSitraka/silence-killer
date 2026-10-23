import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_icons.dart';
import 'setup_screen.dart';

/// Une page du tutoriel.
class _TutoPage {
  const _TutoPage({required this.title, required this.text, required this.illustration, required this.color});

  final String title;
  final String text;
  final Widget illustration;
  final Color color;
}

/// Tutoriel illustré en plusieurs pages (PageView + indicateur de points).
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _page = 0;

  static Widget _emoji(String e, {double size = 90}) => Text(e, style: TextStyle(fontSize: size));

  static final List<_TutoPage> _pages = [
    _TutoPage(
      title: '1. Préparation',
      color: const Color(0xFFFFE8F1),
      illustration: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Wiggle(phase: i.toDouble(), child: PlayerAvatar(colorIndex: i, size: 66)),
            ),
        ],
      ),
      text: 'Choisissez le nombre de joueurs, entrez leurs prénoms, '
          "puis le nombre d'assassins.\n\nLe nombre de citoyens est calculé tout seul !",
    ),
    _TutoPage(
      title: '2. Les rôles secrets',
      color: const Color(0xFFE6F6FF),
      illustration: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RoleIcon(role: Role.citizen, size: 100),
          _emoji('📱', size: 60),
          const RoleIcon(role: Role.assassin, size: 110),
        ],
      ),
      text: 'On se passe le téléphone. Chaque joueur voit son prénom, appuie pour '
          'découvrir son rôle (Citoyen ou Assassin), le mémorise, puis valide.\n\n'
          "L'écran affiche alors le prénom du joueur suivant : personne ne voit le rôle des autres !",
    ),
    _TutoPage(
      title: '3. Chut… silence !',
      color: const Color(0xFFFFF4D6),
      illustration: Wiggle(child: _emoji('🤫', size: 110)),
      text: 'Pendant la partie, PERSONNE NE PARLE.\n\n'
          'Les joueurs se regardent seulement… dans les yeux 👀\n'
          'Posez le téléphone au centre de la table.',
    ),
    _TutoPage(
      title: "4. Le clin d'œil qui tue",
      color: const Color(0xFFF1EAFF),
      illustration: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Wiggle(child: RoleIcon(role: Role.assassin, size: 110)),
          _emoji('😉', size: 50),
          const PlayerAvatar(colorIndex: 2, alive: false, size: 80),
        ],
      ),
      text: "Un assassin tue quelqu'un en lui faisant un clin d'œil.\n\n"
          "La victime doit attendre 2 secondes avant d'annoncer qu'elle est morte, "
          "pour ne pas trahir l'assassin trop vite. On la marque ensuite « Mort 💀 » dans l'appli.",
    ),
    _TutoPage(
      title: "5. J'ai un soupçon !",
      color: const Color(0xFFE5FAF0),
      illustration: Wiggle(angle: 0.15, child: _emoji('✋', size: 110)),
      text: "Si un joueur soupçonne quelqu'un, il lève la main.\n\n"
          'Les autres joueurs doivent valider qu\'on peut passer au vote. '
          "On appuie alors sur « J'accuse ! ✋ ».",
    ),
    const _TutoPage(
      title: "6. L'accusation",
      color: Color(0xFFFFEDE3),
      illustration: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ResultBubble(
            icon: RoleIcon(role: Role.assassin, size: 70),
            label: 'Assassin ?\nIl est éliminé',
            color: AppColors.mint,
          ),
          SizedBox(width: 12),
          _ResultBubble(
            icon: RoleIcon(role: Role.citizen, size: 70),
            label: 'Innocent ?\nLes 2 meurent',
            color: AppColors.coral,
          ),
        ],
      ),
      text: "L'accusateur désigne un joueur.\n\n"
          "Si c'est un assassin, l'assassin est éliminé. Si ce n'est PAS un assassin, "
          "l'accusateur ET l'accusé meurent tous les deux. Réfléchis bien !",
    ),
    _TutoPage(
      title: '7. Qui gagne ?',
      color: const Color(0xFFFFF4D6),
      illustration: Wiggle(child: _emoji('🏆', size: 110)),
      text: 'Les CITOYENS gagnent quand tous les assassins sont éliminés.\n\n'
          'Les ASSASSINS gagnent quand il ne reste que 2 citoyens pour 1 assassin vivant '
          '(3 citoyens pour 2 assassins, 4 pour 3, etc.).',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: page.color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Comment jouer ?'), actions: const [MuteButton()]),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => _TutoPageView(page: _pages[i]),
                ),
              ),
              // Indicateur de points.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: i == _page ? 28 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: i == _page ? AppColors.assassinPurple : AppColors.lavender.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: BigButton(
                    label: _isLast ? "J'ai compris, on joue !" : 'Suivant',
                    emoji: _isLast ? '🎉' : '👉',
                    color: _isLast ? AppColors.pink : AppColors.lavender,
                    onPressed: _next,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutoPageView extends StatelessWidget {
  const _TutoPageView({required this.page});

  final _TutoPage page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(height: 150, child: Center(child: BounceIn(child: page.illustration))),
          const SizedBox(height: 16),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.assassinPurple),
          ),
          const SizedBox(height: 16),
          RoundCard(
            child: Text(
              page.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, height: 1.35, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBubble extends StatelessWidget {
  const _ResultBubble({required this.icon, required this.label, required this.color});

  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.1),
          ),
        ],
      ),
    );
  }
}
