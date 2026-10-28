import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'browser_services.dart' as browser;

void main() => runApp(const MirrorGame());

class MirrorGame extends StatelessWidget {
  const MirrorGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Зеркало времени',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffc88b50),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Georgia',
      ),
      home: const GamePage(),
    );
  }
}

/// Visual theme of the era map.
enum EraScene { medieval, sea, modern }

class Era {
  const Era({required this.name, required this.years, required this.icon,
    required this.color, required this.scene, required this.markerIcons, required this.questions});
  final String name;
  final String years;
  final IconData icon;
  final Color color;
  final EraScene scene;
  /// Map marker icon for each question (same order as [questions]).
  final List<IconData> markerIcons;
  final List<HistoryQuestion> questions;

  String get storageKey => 'mirror_of_time.stars.$name';
}

class HistoryQuestion {
  const HistoryQuestion(this.text, this.options, this.answer, this.fact);
  final String text;
  final List<String> options;
  final int answer;
  final String fact;
}

const eras = <Era>[
  Era(name: 'Средневековье', years: 'V — XV века', icon: Icons.castle_outlined,
    color: Color(0xffbd8150), scene: EraScene.medieval,
    markerIcons: [Icons.shield_outlined, Icons.handyman_outlined, Icons.church_outlined],
    questions: [
      HistoryQuestion('Как называли воина в тяжёлых доспехах, служившего феодалу?',
        ['Рыцарь', 'Гладиатор', 'Легионер'], 0,
        'Рыцари служили сеньору и проходили долгую военную подготовку.'),
      HistoryQuestion('Как назывались объединения ремесленников одной профессии в средневековых городах?',
        ['Сенаты', 'Цехи', 'Трибы'], 1,
        'Цехи следили за качеством товаров, обучали учеников и защищали своих мастеров.'),
      HistoryQuestion('Как называется стиль соборов с острыми арками, высокими шпилями и витражами?',
        ['Романский', 'Барокко', 'Готика'], 2,
        'Готические соборы, например Нотр-Дам в Париже, строили десятилетиями, иногда целыми поколениями.'),
    ]),
  Era(name: 'Эпоха великих открытий', years: 'XV — XVII века', icon: Icons.sailing,
    color: Color(0xff61969b), scene: EraScene.sea,
    markerIcons: [Icons.flag_outlined, Icons.explore_outlined, Icons.sailing],
    questions: [
      HistoryQuestion('Кто в 1492 году достиг островов Карибского моря, плывя на запад?',
        ['Васко да Гама', 'Христофор Колумб', 'Фернан Магеллан'], 1,
        'Экспедиция Колумба достигла Карибских островов в 1492 году.'),
      HistoryQuestion('Какой морской прибор помогает определить стороны света?',
        ['Компас', 'Телескоп', 'Барометр'], 0,
        'Компас позволял мореплавателям ориентироваться вдали от берега.'),
      HistoryQuestion('Как назывался корабль, на котором Магеллан отправился в кругосветное плавание?',
        ['«Санта-Мария»', '«Виктория»', '«Золотая лань»'], 1,
        '«Виктория» вернулась в Испанию в 1522 году, завершив первое кругосветное плавание.'),
    ]),
  Era(name: 'Новейшее время', years: 'XX — XXI века', icon: Icons.rocket_launch_outlined,
    color: Color(0xff8c83bd), scene: EraScene.modern,
    markerIcons: [Icons.rocket_launch_outlined, Icons.satellite_alt_outlined, Icons.language],
    questions: [
      HistoryQuestion('В каком году Юрий Гагарин совершил первый полёт человека в космос?',
        ['1957', '1961', '1969'], 1,
        'Полёт Юрия Гагарина на корабле «Восток-1» состоялся 12 апреля 1961 года.'),
      HistoryQuestion('Как назывался первый искусственный спутник Земли, запущенный в 1957 году?',
        ['«Спутник-1»', '«Восток-1»', '«Аполлон-11»'], 0,
        '4 октября 1957 года СССР вывел на орбиту «Спутник-1» — так началась космическая эра.'),
      HistoryQuestion('Как называется всемирная компьютерная сеть, ставшая доступной широкой публике в 1990-х?',
        ['Интернет', 'Трансатлантический кабель', 'Радио'], 0,
        'В 1990-х интернет быстро вошёл в повседневную жизнь людей.'),
    ]),
];

/// Number of cracks after which the mirror breaks and the era is failed.
const maxCracks = 3;
const _mapPoints = [Offset(.30, .58), Offset(.51, .39), Offset(.72, .58)];
const _startPosition = Offset(.14, .55);

enum Stage { home, map, question, result }

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final _random = Random();
  Stage stage = Stage.home;
  Era? selectedEra;
  int questionIndex = 0;
  /// Questions answered correctly on the first try.
  int score = 0;
  int cracks = 0;
  /// Original (unshuffled) index of the chosen option.
  int? selectedAnswer;
  bool answered = false;
  bool missedCurrent = false;
  List<int> optionOrder = const [];
  Offset playerPosition = _startPosition;
  bool traveling = false;
  final Set<int> completedQuestions = <int>{};
  int speechKey = 0;
  bool voiceEnabled = true;
  final Map<String, int> bestStars = <String, int>{};
  int earnedStars = 0;
  bool newRecord = false;

  bool get failed => cracks >= maxCracks;
  HistoryQuestion get currentQuestion => selectedEra!.questions[questionIndex];
  int get totalStars => bestStars.values.fold(0, (sum, s) => sum + s);

  @override
  void initState() {
    super.initState();
    _loadStars();
  }

  @override
  void dispose() {
    stopSpeech();
    super.dispose();
  }

  void _loadStars() {
    for (final era in eras) {
      final value = int.tryParse(browser.readStorage(era.storageKey) ?? '');
      if (value != null) bestStars[era.name] = value.clamp(0, maxCracks);
    }
  }

  void _saveStars(Era era, int stars) {
    bestStars[era.name] = stars;
    browser.writeStorage(era.storageKey, '$stars');
  }

  void stopSpeech() => browser.stopSpeech();

  void speakQuestion() {
    if (!voiceEnabled || selectedEra == null || stage != Stage.question) return;
    browser.speak(currentQuestion.text);
  }

  void toggleVoice() {
    if (voiceEnabled) stopSpeech();
    setState(() => voiceEnabled = !voiceEnabled);
  }

  List<int> _shuffledOptions() =>
    List<int>.generate(currentQuestion.options.length, (i) => i)..shuffle(_random);

  void startEra(Era era) {
    stopSpeech();
    setState(() {
      selectedEra = era;
      stage = Stage.map;
      questionIndex = 0;
      score = 0;
      cracks = 0;
      selectedAnswer = null;
      answered = false;
      missedCurrent = false;
      playerPosition = _startPosition;
      traveling = false;
      completedQuestions.clear();
      earnedStars = 0;
      newRecord = false;
    });
  }

  void chooseAnswer(int option) {
    if (answered) return;
    stopSpeech();
    setState(() {
      selectedAnswer = option;
      answered = true;
      if (option == currentQuestion.answer) {
        if (completedQuestions.add(questionIndex) && !missedCurrent) score++;
      } else {
        missedCurrent = true;
        cracks++;
      }
    });
  }

  void nextQuestion() {
    stopSpeech();
    if (failed) return _finish();
    if (selectedAnswer != currentQuestion.answer) {
      setState(() {
        selectedAnswer = null;
        answered = false;
        optionOrder = _shuffledOptions();
        speechKey++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => speakQuestion());
      return;
    }
    if (completedQuestions.length == selectedEra!.questions.length) return _finish();
    setState(() {
      selectedAnswer = null;
      answered = false;
      stage = Stage.map;
    });
  }

  void _finish() {
    final era = selectedEra!;
    setState(() {
      earnedStars = failed ? 0 : maxCracks - cracks;
      newRecord = earnedStars > (bestStars[era.name] ?? 0);
      if (newRecord) _saveStars(era, earnedStars);
      stage = Stage.result;
    });
  }

  Future<void> travelToQuestion(int index) async {
    if (traveling || completedQuestions.contains(index)) return;
    setState(() {
      questionIndex = index;
      selectedAnswer = null;
      answered = false;
      missedCurrent = false;
      optionOrder = _shuffledOptions();
      traveling = true;
      playerPosition = _mapPoints[index];
    });
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted || selectedEra == null) return;
    setState(() {
      traveling = false;
      stage = Stage.question;
      speechKey++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => speakQuestion());
  }

  void goHome() {
    stopSpeech();
    setState(() {
      stage = Stage.home;
      selectedEra = null;
      selectedAnswer = null;
      answered = false;
      traveling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xff111b23), Color(0xff1b292e), Color(0xff11181e)]),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 52, vertical: 24),
                child: switch (stage) {
                  Stage.home => _buildHome(compact),
                  Stage.map => _buildWorld(compact),
                  Stage.question => _buildQuestion(compact),
                  Stage.result => _buildResult(compact),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() => Row(children: [
    _IconButton(icon: Icons.arrow_back, onTap: goHome),
    const Spacer(),
    const _Brand(),
    const Spacer(),
    _CracksIndicator(cracks: cracks),
    const SizedBox(width: 10),
    IconButton.filledTonal(
      tooltip: voiceEnabled ? 'Выключить озвучку' : 'Включить озвучку',
      onPressed: toggleVoice,
      icon: Icon(voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
    ),
  ]);

  Widget _buildHome(bool compact) => Center(child: SingleChildScrollView(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Brand(),
        const SizedBox(height: 34),
        _MirrorCard(mood: 'curious', compact: compact,
          title: 'ЗЕРКАЛО ВРЕМЕНИ', subtitle: 'Три эпохи. Девять загадок.\nПроверь, что помнит история.'),
        const SizedBox(height: 30),
        Text('ВЫБЕРИ ЭПОХУ', style: _eyebrow),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: eras.map((era) => _EraButton(era: era, stars: bestStars[era.name] ?? 0,
            onTap: () => startEra(era))).toList()),
        const SizedBox(height: 18),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, size: 18, color: Color(0xffe2b47b)),
          const SizedBox(width: 5),
          Text('$totalStars / ${eras.length * maxCracks} звёзд собрано',
            style: const TextStyle(color: Color(0xffd4c3aa), fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        const Text('Каждая ошибка оставляет трещину на зеркале и отнимает звезду.\nТри трещины — и зеркало разобьётся.',
          textAlign: TextAlign.center, style: TextStyle(color: Color(0xffa4adae), fontSize: 13, height: 1.4)),
      ],
    ),
  ));

  Widget _buildQuestion(bool compact) {
    final era = selectedEra!;
    final question = currentQuestion;
    final correct = answered && selectedAnswer == question.answer;
    final reveal = answered && (correct || failed);
    final String title;
    final String subtitle;
    if (!answered) {
      title = 'СЛУШАЙ ВРЕМЯ';
      subtitle = 'Зеркало задаёт\nвопрос из эпохи:';
    } else if (correct) {
      title = 'МУДРО!';
      subtitle = missedCurrent ? 'Верно, хоть и не с первого раза.' : 'Зеркало довольно\nтвоим ответом.';
    } else if (failed) {
      title = 'ЗЕРКАЛО РАЗБИЛОСЬ';
      subtitle = 'Третья трещина…\nВремя ускользнуло.';
    } else {
      final left = maxCracks - cracks;
      title = 'ХМ… ТРЕЩИНА!';
      subtitle = 'Ошибка оставила след.\n${left == 1 ? 'Осталась последняя попытка' : 'Ещё можно ошибиться: ${left - 1}'}.';
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(),
          SizedBox(height: compact ? 20 : 34),
          _MirrorCard(mood: answered ? (correct ? 'happy' : 'angry') : 'speaking',
            compact: compact, cracks: cracks, title: title, subtitle: subtitle),
          const SizedBox(height: 18),
          _ProgressBar(value: completedQuestions.length / era.questions.length, color: era.color),
          const SizedBox(height: 18),
          Text('${era.name.toUpperCase()}  ·  ${era.years}', style: TextStyle(fontSize: 11, letterSpacing: 2.2, color: era.color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _SpeakingQuestion(key: ValueKey(speechKey), text: question.text,
            compact: compact, onFinished: () {}),
          const SizedBox(height: 18),
          ...List.generate(optionOrder.length, (position) {
            final option = optionOrder[position];
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _AnswerButton(label: question.options[option], index: position,
                correct: reveal && question.answer == option, selected: selectedAnswer == option,
                answered: answered, onTap: () => chooseAnswer(option)),
            );
          }),
          if (answered) ...[
            const SizedBox(height: 4),
            if (reveal) ...[
              Text(question.fact, textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xffc1c6c2), height: 1.4, fontSize: 13)),
              const SizedBox(height: 14),
            ],
            _PrimaryButton(label: failed
                ? 'К ИТОГАМ'
                : correct
                  ? (completedQuestions.length == era.questions.length ? 'ЗАВЕРШИТЬ ПУТЕШЕСТВИЕ' : 'ОТКРЫТЬ СЛЕДУЮЩИЙ ПУТЬ')
                  : 'ПОПРОБОВАТЬ ЕЩЁ РАЗ',
              onTap: nextQuestion),
          ],
        ],
      ),
    );
  }

  Widget _buildWorld(bool compact) {
    final era = selectedEra!;
    return Column(children: [
      _buildTopBar(),
      const SizedBox(height: 12),
      Text('${era.name.toUpperCase()}  ·  ${era.years}', style: TextStyle(fontSize: 11, letterSpacing: 2.2, color: era.color, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Карта вопросов', style: TextStyle(fontSize: compact ? 22 : 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      const Text('Выбери место на карте, куда отправиться за вопросом.', textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xffa4adae), fontSize: 13)),
      const SizedBox(height: 14),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(24), child: LayoutBuilder(builder: (context, bounds) {
          final w = bounds.maxWidth;
          final h = bounds.maxHeight;
          return Stack(fit: StackFit.expand, children: [
            CustomPaint(painter: _WorldPainter(color: era.color, scene: era.scene)),
            Positioned(left: w * .77, top: h * .18, width: w * .13, height: h * .39,
              child: _WorldMirror(glowing: true, color: era.color)),
            AnimatedPositioned(duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic,
              left: playerPosition.dx * w - 22, top: playerPosition.dy * h - 30,
              child: _WorldHero(color: era.color)),
            Positioned(left: 14, top: 14, child: _MapBadge(icon: Icons.person, text: 'ПУТЕШЕСТВЕННИК')),
            ...List.generate(era.questions.length, (index) {
              final point = _mapPoints[index];
              final complete = completedQuestions.contains(index);
              return Positioned(left: w * point.dx - 23, top: h * point.dy - 23,
                child: _QuestionMarker(index: index, complete: complete,
                  color: era.color, icon: era.markerIcons[index], disabled: traveling || complete,
                  onTap: () => travelToQuestion(index)));
            }),
            if (traveling) Positioned(left: 0, right: 0, bottom: 20,
              child: Center(child: _MapBadge(icon: Icons.directions_walk, text: 'ИДЁМ К ВОПРОСУ'))),
          ]);
        }))),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center,
        children: List.generate(era.questions.length, (index) {
          final complete = completedQuestions.contains(index);
          return _MapQuestionChip(
            index: index, complete: complete, color: era.color,
            onTap: traveling || complete ? null : () => travelToQuestion(index));
        }),
      ),
      const SizedBox(height: 8),
      Text('${completedQuestions.length} из ${era.questions.length} вопросов открыто',
        textAlign: TextAlign.center, style: const TextStyle(color: Color(0xffb4b8b4), fontSize: 12)),
    ]);
  }

  Widget _buildResult(bool compact) {
    final era = selectedEra!;
    final total = era.questions.length;
    final mood = failed ? 'angry' : (earnedStars >= 2 ? 'happy' : 'curious');
    final headline = failed ? 'ЗЕРКАЛО РАЗБИЛОСЬ' :
      (earnedStars == 3 ? 'ИСТИННЫЙ ЗНАТОК!' : (earnedStars == 2 ? 'ОТЛИЧНЫЙ ПУТЬ!' : 'ПУТЬ ПРОЙДЕН'));
    final message = failed ? 'Три трещины — и время ускользнуло.\nИстория любит упорных: попробуй снова.' :
      (earnedStars == 3 ? 'Ни одной трещины! Зеркало сияет: ты прекрасно знаешь эту эпоху.' :
      (earnedStars == 2 ? 'Хранитель времени доволен. Пройди без ошибок, чтобы получить все звёзды.' :
      'Зеркало уцелело, но трещин многовато. Попробуй собрать больше звёзд.'));
    return Center(child: SingleChildScrollView(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [_IconButton(icon: Icons.arrow_back, onTap: goHome), const Spacer(), const _Brand(), const Spacer(), const SizedBox(width: 44)]),
        const SizedBox(height: 26),
        _MirrorCard(mood: mood, compact: compact, cracks: cracks, title: headline, subtitle: message),
        const SizedBox(height: 22),
        _StarsRow(stars: earnedStars, size: 46),
        if (newRecord) ...[
          const SizedBox(height: 6),
          const Text('НОВЫЙ РЕКОРД!', style: TextStyle(fontSize: 12, letterSpacing: 2, color: Color(0xffe2b47b), fontWeight: FontWeight.bold)),
        ],
        const SizedBox(height: 14),
        Text('$score из $total', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xffe2b47b))),
        const SizedBox(height: 5),
        Text('с первой попытки · трещин: $cracks · ${era.name}', textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xffa4adae))),
        const SizedBox(height: 22),
        if (failed) ...[
          _PrimaryButton(label: 'ПОПРОБОВАТЬ СНОВА', onTap: () => startEra(era)),
          const SizedBox(height: 10),
          TextButton(onPressed: goHome, child: const Text('ВЫБРАТЬ ДРУГУЮ ЭПОХУ')),
        ] else ...[
          _PrimaryButton(label: 'ВЫБРАТЬ ДРУГУЮ ЭПОХУ', onTap: goHome),
          const SizedBox(height: 10),
          TextButton(onPressed: () => startEra(era), child: const Text('ПРОЙТИ ЕЩЁ РАЗ')),
        ],
      ]),
    ));
  }
}


const _eyebrow = TextStyle(fontSize: 11, letterSpacing: 2.2, color: Color(0xffa4adae), fontWeight: FontWeight.w600);

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: const [
    Icon(Icons.auto_awesome, size: 17, color: Color(0xffdbab73)),
    SizedBox(width: 7), Text('ХРОНИКИ ВРЕМЕНИ', style: TextStyle(letterSpacing: 2, fontSize: 10, color: Color(0xffd4c3aa), fontWeight: FontWeight.bold)),
  ]);
}

class _WorldPainter extends CustomPainter {
  const _WorldPainter({required this.color, required this.scene});
  final Color color;
  final EraScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final background = Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: switch (scene) {
        EraScene.medieval => const [Color(0xff29413d), Color(0xff1b302e), Color(0xff263936)],
        EraScene.sea => const [Color(0xff2c4140), Color(0xff22382f), Color(0xff2b3d36)],
        EraScene.modern => const [Color(0xff2a2c3f), Color(0xff1f2233), Color(0xff292b3d)],
      },
    ).createShader(bounds);
    canvas.drawRect(bounds, background);

    final pathPaint = Paint()..color = const Color(0xff9d8061).withValues(alpha: .25);
    final path = Path()
      ..moveTo(size.width * .06, size.height * .61)
      ..cubicTo(size.width * .28, size.height * .48, size.width * .36, size.height * .75,
          size.width * .54, size.height * .55)
      ..cubicTo(size.width * .65, size.height * .43, size.width * .64, size.height * .40,
          size.width * .80, size.height * .48)
      ..lineTo(size.width * .80, size.height * .63)
      ..cubicTo(size.width * .63, size.height * .55, size.width * .69, size.height * .58,
          size.width * .57, size.height * .68)
      ..cubicTo(size.width * .35, size.height * .88, size.width * .27, size.height * .61,
          size.width * .06, size.height * .75)
      ..close();
    canvas.drawPath(path, pathPaint);

    final stonePaint = Paint()..color = const Color(0xffd4c2a2).withValues(alpha: .20);
    for (var i = 0; i < 9; i++) {
      final t = i / 8;
      final x = size.width * (.08 + t * .68);
      final y = size.height * (.68 - .10 * (t < .65 ? t : .65));
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 18, height: 8), stonePaint);
    }

    switch (scene) {
      case EraScene.medieval:
        _paintCastle(canvas, size);
        _paintBushes(canvas, size, [
          Offset(size.width * .43, size.height * .19), Offset(size.width * .57, size.height * .22),
          Offset(size.width * .90, size.height * .21), Offset(size.width * .91, size.height * .72),
          Offset(size.width * .37, size.height * .83), Offset(size.width * .14, size.height * .83),
        ]);
      case EraScene.sea:
        _paintSea(canvas, size);
        _paintBushes(canvas, size, [
          Offset(size.width * .91, size.height * .72), Offset(size.width * .37, size.height * .86),
          Offset(size.width * .14, size.height * .84),
        ]);
      case EraScene.modern:
        _paintCity(canvas, size);
    }

    final sparkle = Paint()..color = color.withValues(alpha: .55);
    for (final p in [Offset(size.width * .73, size.height * .30), Offset(size.width * .87, size.height * .42), Offset(size.width * .69, size.height * .65)]) {
      canvas.drawCircle(p, 2.5, sparkle);
    }
    final vignette = Paint()..shader = RadialGradient(
      colors: [Colors.transparent, const Color(0xff07110f).withValues(alpha: .48)],
      stops: const [.48, 1],
    ).createShader(bounds);
    canvas.drawRect(bounds, vignette);
  }

  void _paintBushes(Canvas canvas, Size size, List<Offset> clusters) {
    final bush = Paint()..color = const Color(0xff142722).withValues(alpha: .78);
    final bushHighlight = Paint()..color = const Color(0xff54765c).withValues(alpha: .36);
    for (final p in clusters) {
      canvas.drawCircle(p, 18, bush);
      canvas.drawCircle(p.translate(-5, -4), 8, bushHighlight);
      canvas.drawCircle(p.translate(8, -1), 9, bushHighlight);
    }
  }

  void _paintCastle(Canvas canvas, Size size) {
    final wall = Paint()..color = const Color(0xff13211f).withValues(alpha: .85);
    final light = Paint()..color = color.withValues(alpha: .55);
    final left = size.width * .08;
    final base = size.height * .33;
    final w = size.width * .26;
    final h = size.height * .12;
    canvas.drawRect(Rect.fromLTRB(left, base - h, left + w, base), wall);
    // Battlements.
    for (var i = 0; i < 7; i++) {
      final x = left + w * i / 6.5;
      canvas.drawRect(Rect.fromLTWH(x, base - h - 7, w / 16, 7), wall);
    }
    // Towers with conical roofs.
    for (final t in [0.0, .5, 1.0]) {
      final cx = left + w * t;
      final tw = size.width * .045;
      final th = h * (t == .5 ? 1.9 : 1.5);
      canvas.drawRect(Rect.fromLTRB(cx - tw / 2, base - th, cx + tw / 2, base), wall);
      canvas.drawPath(Path()
        ..moveTo(cx - tw * .7, base - th)
        ..lineTo(cx, base - th - tw * 1.3)
        ..lineTo(cx + tw * .7, base - th)
        ..close(), wall);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, base - th * .65), width: 4, height: 8), const Radius.circular(2)), light);
    }
    // Gate.
    canvas.drawRRect(RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(left + w * .5, base - h * .3), width: w * .12, height: h * .6),
      topLeft: const Radius.circular(20), topRight: const Radius.circular(20)), light..color = color.withValues(alpha: .3));
  }

  void _paintSea(Canvas canvas, Size size) {
    final waterRect = Rect.fromLTRB(0, 0, size.width, size.height * .34);
    final water = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xff16323c), Color(0xff1f4650)]).createShader(waterRect);
    final shore = Path()
      ..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width, size.height * .28);
    for (var i = 10; i >= 0; i--) {
      final x = size.width * i / 10;
      shore.lineTo(x, size.height * (.31 + .03 * sin(i * 1.7)));
    }
    shore.close();
    canvas.drawPath(shore, water);
    final wave = Paint()
      ..color = const Color(0xff9fd0d0).withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final row in [.08, .16, .24]) {
      for (var i = 0; i < 6; i++) {
        final x = size.width * (.06 + i * .16 + (row == .16 ? .07 : 0));
        final y = size.height * row;
        canvas.drawPath(Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 8, y - 5, x + 16, y)
          ..quadraticBezierTo(x + 24, y + 5, x + 32, y), wave);
      }
    }
    // Small caravel.
    final ship = Offset(size.width * .30, size.height * .17);
    final hull = Paint()..color = const Color(0xff3b2a20);
    final sail = Paint()..color = const Color(0xffe9dcc1).withValues(alpha: .85);
    canvas.drawPath(Path()
      ..moveTo(ship.dx - 26, ship.dy)
      ..lineTo(ship.dx + 26, ship.dy)
      ..lineTo(ship.dx + 18, ship.dy + 10)
      ..lineTo(ship.dx - 18, ship.dy + 10)
      ..close(), hull);
    canvas.drawRect(Rect.fromLTWH(ship.dx - 1, ship.dy - 34, 2, 34), hull);
    canvas.drawPath(Path()
      ..moveTo(ship.dx + 2, ship.dy - 32)..lineTo(ship.dx + 22, ship.dy - 6)..lineTo(ship.dx + 2, ship.dy - 6)..close(), sail);
    canvas.drawPath(Path()
      ..moveTo(ship.dx - 2, ship.dy - 26)..lineTo(ship.dx - 18, ship.dy - 6)..lineTo(ship.dx - 2, ship.dy - 6)..close(), sail);
    canvas.drawRect(Rect.fromLTWH(ship.dx - 1, ship.dy - 40, 9, 5), Paint()..color = color);
  }

  void _paintCity(Canvas canvas, Size size) {
    final star = Paint()..color = const Color(0xffeae4ff).withValues(alpha: .55);
    final rnd = Random(7);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(Offset(size.width * rnd.nextDouble(), size.height * rnd.nextDouble() * .22),
        rnd.nextDouble() * 1.3 + .4, star);
    }
    final building = Paint()..color = const Color(0xff141626).withValues(alpha: .9);
    final window = Paint()..color = const Color(0xffffe1a3).withValues(alpha: .45);
    final base = size.height * .33;
    var x = size.width * .04;
    while (x < size.width * .70) {
      final bw = size.width * (.035 + rnd.nextDouble() * .03);
      final bh = size.height * (.06 + rnd.nextDouble() * .14);
      canvas.drawRect(Rect.fromLTWH(x, base - bh, bw, bh), building);
      for (var wy = base - bh + 6; wy < base - 6; wy += 9) {
        for (var wx = x + 4; wx < x + bw - 4; wx += 7) {
          if (rnd.nextDouble() < .45) canvas.drawRect(Rect.fromLTWH(wx, wy, 3, 4), window);
        }
      }
      x += bw + 3;
    }
    // TV tower.
    final tx = size.width * .58;
    canvas.drawRect(Rect.fromLTWH(tx - 2, base - size.height * .27, 4, size.height * .27), building);
    canvas.drawCircle(Offset(tx, base - size.height * .2), 6, building);
    canvas.drawCircle(Offset(tx, base - size.height * .27), 2.5, Paint()..color = const Color(0xffff8a7a));
    // Rocket on the launch pad.
    final r = Offset(size.width * .90, size.height * .86);
    final body = Paint()..color = const Color(0xffdcd8ea);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: r, width: 12, height: 40), const Radius.circular(6)), body);
    canvas.drawPath(Path()..moveTo(r.dx - 6, r.dy - 14)..lineTo(r.dx, r.dy - 30)..lineTo(r.dx + 6, r.dy - 14)..close(),
      Paint()..color = color);
    canvas.drawPath(Path()..moveTo(r.dx - 6, r.dy + 8)..lineTo(r.dx - 13, r.dy + 20)..lineTo(r.dx - 6, r.dy + 18)..close(), Paint()..color = color);
    canvas.drawPath(Path()..moveTo(r.dx + 6, r.dy + 8)..lineTo(r.dx + 13, r.dy + 20)..lineTo(r.dx + 6, r.dy + 18)..close(), Paint()..color = color);
    canvas.drawCircle(r.translate(0, -4), 3, Paint()..color = const Color(0xff4d5f8c));
  }

  @override
  bool shouldRepaint(covariant _WorldPainter oldDelegate) => oldDelegate.color != color || oldDelegate.scene != scene;
}

class _WorldMirror extends StatelessWidget {
  const _WorldMirror({required this.glowing, required this.color});
  final bool glowing;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(60),
      color: const Color(0xff172629),
      border: Border.all(color: glowing ? const Color(0xffffdfad) : color.withValues(alpha: .8), width: 4),
      boxShadow: [BoxShadow(color: color.withValues(alpha: glowing ? .8 : .28), blurRadius: glowing ? 35 : 18, spreadRadius: glowing ? 7 : 2)],
    ),
    child: Center(child: Container(
      margin: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        gradient: RadialGradient(colors: [color.withValues(alpha: .4), const Color(0xff182b31)]),
      ),
      child: const Center(child: Icon(Icons.auto_awesome, size: 32, color: Color(0xffffdfad))),
    )),
  );
}

class _WorldHero extends StatelessWidget {
  const _WorldHero({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle,
      color: const Color(0xffffd493), border: Border.all(color: const Color(0xff533d32), width: 2))),
    Container(width: 23, height: 29, decoration: BoxDecoration(color: color,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(5)),
      border: Border.all(color: const Color(0xffffd493), width: 1.5))),
    Container(width: 30, height: 7, decoration: BoxDecoration(color: Colors.black.withValues(alpha: .25), borderRadius: BorderRadius.circular(50))),
  ]);
}

class _QuestionMarker extends StatelessWidget {
  const _QuestionMarker({required this.index, required this.complete, required this.color,
    required this.icon, required this.disabled, required this.onTap});
  final int index;
  final bool complete;
  final Color color;
  final IconData icon;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Открыть вопрос ${index + 1}',
    child: AnimatedScale(
      scale: complete ? .9 : 1,
      duration: const Duration(milliseconds: 250),
      child: Material(
        color: complete ? const Color(0xff527c68) : const Color(0xff172629),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: disabled ? null : onTap,
          customBorder: const CircleBorder(),
          child: Container(width: 46, height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: complete ? const Color(0xffa5d3aa) : color, width: 2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: complete ? .26 : .65), blurRadius: 16, spreadRadius: 2)]),
            child: Stack(alignment: Alignment.center, children: [
              Icon(complete ? Icons.check : icon, color: const Color(0xffffe4b3), size: 22),
              Positioned(right: -1, bottom: -1, child: Container(width: 17, height: 17,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xffd4aa70), shape: BoxShape.circle),
                child: Text('${index + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xff172126)))),
              ),
            ]),
          ),
        ),
      ),
    ),
  );
}

class _MapQuestionChip extends StatelessWidget {
  const _MapQuestionChip({required this.index, required this.complete, required this.color, required this.onTap});
  final int index;
  final bool complete;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    onPressed: onTap,
    avatar: Icon(complete ? Icons.check_circle : Icons.place_outlined, size: 17, color: complete ? const Color(0xffa5d3aa) : color),
    label: Text('Вопрос ${index + 1}'),
    backgroundColor: const Color(0xff253238),
    side: BorderSide(color: color.withValues(alpha: .45)),
    labelStyle: const TextStyle(fontSize: 12, color: Color(0xffe4ded4)),
  );
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xff101a1b).withValues(alpha: .72), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffc9ab7e).withValues(alpha: .38))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: const Color(0xffe0c18f)),
      const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 9, letterSpacing: 1.1, color: Color(0xffe5d4b4)))]),
  );
}

class _MirrorCard extends StatelessWidget {
  const _MirrorCard({required this.mood, required this.title, required this.subtitle, required this.compact, this.cracks = 0});
  final String mood;
  final String title;
  final String subtitle;
  final bool compact;
  final int cracks;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: compact ? 19 : 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xffc9925d).withValues(alpha: .47), width: 1.2),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xff354247), Color(0xff202b30), Color(0xff172126)]),
        boxShadow: [BoxShadow(color: const Color(0xffca8c50).withValues(alpha: .09), blurRadius: 28, spreadRadius: 2)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: compact ? 70 : 86, height: compact ? 70 : 86,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: const Color(0xffd9b58a).withValues(alpha: .12),
            border: Border.all(color: const Color(0xffd9b58a).withValues(alpha: .55), width: 2)),
          child: Stack(fit: StackFit.expand, children: [
            _AnimatedFace(mood: mood, size: compact ? 70 : 86),
            if (cracks > 0) IgnorePointer(child: ClipOval(child: TweenAnimationBuilder<double>(
              key: ValueKey(cracks),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) => CustomPaint(
                painter: _CrackPainter(cracks: cracks, lastProgress: progress)),
            ))),
          ]),
        ),
        const SizedBox(width: 19),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: compact ? 17 : 20, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: const Color(0xffe5c89f))),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: compact ? 13 : 15, height: 1.4, color: const Color(0xffc1c9c5))),
        ])),
      ]),
    );
  }
}

class _SpeakingQuestion extends StatefulWidget {
  const _SpeakingQuestion({super.key, required this.text, required this.compact, required this.onFinished});
  final String text;
  final bool compact;
  final VoidCallback onFinished;

  @override
  State<_SpeakingQuestion> createState() => _SpeakingQuestionState();
}

class _SpeakingQuestionState extends State<_SpeakingQuestion> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int visibleCharacters = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: widget.text.length * 24))
      ..addListener(() {
        final next = (widget.text.length * _controller.value).ceil();
        if (next != visibleCharacters && mounted) setState(() => visibleCharacters = next);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xff253238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffd4a772).withValues(alpha: .42)),
        boxShadow: [BoxShadow(color: const Color(0xffd4a772).withValues(alpha: .06 + .06 * _controller.value), blurRadius: 18)],
      ),
      child: Text(widget.text.substring(0, visibleCharacters.clamp(0, widget.text.length)),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: widget.compact ? 21 : 27, height: 1.3, fontWeight: FontWeight.w600, color: const Color(0xfff0e7d8))),
    ),
  );
}

class _AnimatedFace extends StatefulWidget {
  const _AnimatedFace({required this.mood, required this.size});
  final String mood;
  final double size;

  @override
  State<_AnimatedFace> createState() => _AnimatedFaceState();
}

class _AnimatedFaceState extends State<_AnimatedFace> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  late final AnimationController _talk = AnimationController(vsync: this, duration: const Duration(milliseconds: 170))..repeat(reverse: true);
  /// One full blink: close (0–.3), hold (.3–.7), open (.7–1).
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 440));
  Timer? _blinkTimer;

  double get _blinkAmount {
    final t = _blink.value;
    if (t < .3) return t / .3;
    if (t < .7) return 1;
    return (1 - t) / .3;
  }

  @override
  void initState() {
    super.initState();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted && widget.mood != 'angry') _blink.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _float.dispose();
    _talk.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speaking = widget.mood == 'speaking';
    final happy = widget.mood == 'happy';
    final angry = widget.mood == 'angry';
    final d = widget.size;
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _talk, _blink]),
      builder: (context, _) {
        final mouthHeight = speaking ? 5.0 + _talk.value * 8 : (happy ? 8.0 : 4.0);
        return Transform.translate(
          offset: Offset(0, -2 * _float.value),
          child: Stack(alignment: Alignment.center, children: [
            Container(width: d * .77, height: d * .77,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xffe2c39a).withValues(alpha: .22), const Color(0xff8caaa8).withValues(alpha: .08), Colors.transparent]),
                boxShadow: [BoxShadow(color: const Color(0xffd3ad79).withValues(alpha: .16 + (speaking ? .12 * _talk.value : 0)), blurRadius: 18, spreadRadius: 2)])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                _Eye(size: d * .12, angry: angry, blink: _blinkAmount),
                SizedBox(width: d * .13),
                _Eye(size: d * .12, angry: angry, blink: _blinkAmount),
              ]),
              SizedBox(height: d * .11),
              AnimatedContainer(duration: const Duration(milliseconds: 120),
                width: happy ? d * .30 : d * .19,
                height: mouthHeight,
                decoration: BoxDecoration(
                  color: speaking ? const Color(0xfff0c995).withValues(alpha: .82) : Colors.transparent,
                  borderRadius: BorderRadius.vertical(
                    top: happy ? Radius.zero : Radius.circular(d),
                    bottom: happy ? Radius.circular(d) : Radius.zero),
                  border: Border(bottom: BorderSide(color: const Color(0xffe8c99f), width: d * .035)),
                ),
              ),
            ]),
            if (angry) Positioned(top: d * .18, left: d * .19, child: Transform.rotate(angle: -.28, child: _brow(d))),
            if (angry) Positioned(top: d * .18, right: d * .19, child: Transform.rotate(angle: .28, child: _brow(d))),
            if (happy) Positioned(top: d * .43, child: Row(children: [
              _cheek(d), SizedBox(width: d * .32), _cheek(d),
            ])),
          ]),
        );
      },
    );
  }

  Widget _brow(double d) => Container(width: d * .17, height: d * .035,
    decoration: BoxDecoration(color: const Color(0xffe8c99f), borderRadius: BorderRadius.circular(5)));
  Widget _cheek(double d) => Container(width: d * .09, height: d * .045,
    decoration: BoxDecoration(color: const Color(0xffd88472).withValues(alpha: .35), borderRadius: BorderRadius.circular(10)));
}

class _Eye extends StatelessWidget {
  const _Eye({required this.size, required this.angry, required this.blink});
  final double size;
  final bool angry;
  final double blink;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: (size * (angry ? .55 : 1) * (1 - blink * .9)).clamp(1, size),
    decoration: BoxDecoration(color: const Color(0xffe8c99f), borderRadius: BorderRadius.circular(size)),
    child: Align(alignment: const Alignment(0, .25), child: Container(
      width: size * .42, height: size * .42,
      decoration: const BoxDecoration(color: Color(0xff283239), shape: BoxShape.circle),
    )),
  );
}

class _EraButton extends StatelessWidget {
  const _EraButton({required this.era, required this.stars, required this.onTap});
  final Era era;
  final int stars;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(16),
    child: Container(width: 190, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(color: const Color(0xff253238), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: era.color.withValues(alpha: .55))),
      child: Row(children: [
        Icon(era.icon, color: era.color, size: 26), const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(era.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 3), Text(era.years, style: const TextStyle(color: Color(0xffa4adae), fontSize: 11)),
          const SizedBox(height: 5), _StarsRow(stars: stars, size: 15),
        ])),
        const Icon(Icons.chevron_right, color: Color(0xffa4adae), size: 18),
      ]),
    ),
  );
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.index, required this.correct, required this.selected, required this.answered, required this.onTap});
  final String label;
  final int index;
  final bool correct;
  final bool selected;
  final bool answered;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = answered && correct ? const Color(0xff63927a) :
      (answered && selected ? const Color(0xffa75c55) : const Color(0xff344147));
    return SizedBox(width: double.infinity, child: Material(
      color: color.withValues(alpha: answered && (correct || selected) ? .32 : .75),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(onTap: answered ? null : onTap, borderRadius: BorderRadius.circular(14),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .75))),
          child: Row(children: [
            Container(width: 27, height: 27, alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)),
              child: Text(String.fromCharCode(65 + index), style: const TextStyle(fontSize: 11, color: Color(0xffd5c2a5), fontWeight: FontWeight.bold))),
            const SizedBox(width: 12), Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            if (answered && correct) const Icon(Icons.check_circle_outline, color: Color(0xff9bd0ad), size: 19),
            if (answered && selected && !correct) const Icon(Icons.highlight_off, color: Color(0xffe7a097), size: 19),
          ]),
        ),
      ),
    ));
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(backgroundColor: const Color(0xffbd8552), foregroundColor: const Color(0xff172126),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
  );
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(onPressed: onTap, icon: Icon(icon),
    style: IconButton.styleFrom(backgroundColor: const Color(0xff344147), foregroundColor: const Color(0xffd9c3a2)));
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(8),
    child: LinearProgressIndicator(value: value, minHeight: 5, backgroundColor: const Color(0xff344147), color: color));
}

/// Row of [maxCracks] stars, the first [stars] of which are filled.
class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.stars, required this.size});
  final int stars;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Звёзд: $stars из $maxCracks',
    child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(maxCracks, (i) {
      final filled = i < stars;
      return Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, size: size,
        color: filled ? const Color(0xffe2b47b) : const Color(0xff5d6a6d));
    })),
  );
}

/// Small mirrors in the top bar: one per allowed mistake, cracked ones turn red.
class _CracksIndicator extends StatelessWidget {
  const _CracksIndicator({required this.cracks});
  final int cracks;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Трещины на зеркале: $cracks из $maxCracks',
    child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(maxCracks, (i) {
      final cracked = i < cracks;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        width: 15, height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: cracked ? const Color(0xffa75c55).withValues(alpha: .35) : const Color(0xffd9b58a).withValues(alpha: .16),
          border: Border.all(color: cracked ? const Color(0xffe7a097) : const Color(0xffd9b58a), width: 1.5),
        ),
        child: cracked ? const ClipRRect(borderRadius: BorderRadius.all(Radius.circular(10)),
          child: CustomPaint(painter: _CrackPainter(cracks: 1))) : null,
      );
    })),
  );
}

/// Draws up to three jagged cracks across a mirror surface.
class _CrackPainter extends CustomPainter {
  const _CrackPainter({required this.cracks, this.lastProgress = 1});
  final int cracks;
  /// Draw progress (0..1) of the most recent crack, used for the "cracking" animation.
  final double lastProgress;

  static const _patterns = [
    [Offset(.50, 0), Offset(.43, .22), Offset(.57, .38), Offset(.46, .58)],
    [Offset(1, .32), Offset(.80, .42), Offset(.71, .60), Offset(.52, .64)],
    [Offset(0, .72), Offset(.22, .62), Offset(.32, .80), Offset(.50, .70)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xfff3ece0).withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, size.width * .022)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final count = min(cracks, _patterns.length);
    for (var i = 0; i < count; i++) {
      final points = _patterns[i].map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final progress = i == count - 1 ? lastProgress : 1.0;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CrackPainter oldDelegate) =>
    oldDelegate.cracks != cracks || oldDelegate.lastProgress != lastProgress;
}
