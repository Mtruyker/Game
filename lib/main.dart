import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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

class Era {
  const Era({required this.name, required this.years, required this.icon,
    required this.color, required this.questions});
  final String name;
  final String years;
  final IconData icon;
  final Color color;
  final List<HistoryQuestion> questions;
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
    color: Color(0xffbd8150), questions: [
      HistoryQuestion('Как называли воина в тяжёлых доспехах, служившего феодалу?',
        ['Рыцарь', 'Гладиатор', 'Легионер'], 0,
        'Рыцари служили сеньору и проходили долгую военную подготовку.'),
      HistoryQuestion('Как назывался центр средневекового города с рынком и ратушей?',
        ['Форум', 'Площадь', 'Акрополь'], 1,
        'Городская площадь была центром торговли и общественной жизни.'),
      HistoryQuestion('Какой материал помог европейцам строить высокие соборы?',
        ['Железобетон', 'Стеклопластик', 'Камень'], 2,
        'Каменные соборы строили десятилетиями, иногда целыми поколениями.'),
    ]),
  Era(name: 'Эпоха великих открытий', years: 'XV — XVII века', icon: Icons.sailing,
    color: Color(0xff61969b), questions: [
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
    color: Color(0xff8c83bd), questions: [
      HistoryQuestion('В каком году Юрий Гагарин совершил первый полёт человека в космос?',
        ['1957', '1961', '1969'], 1,
        'Полёт Юрия Гагарина на корабле «Восток-1» состоялся 12 апреля 1961 года.'),
      HistoryQuestion('Какое изобретение позволило мгновенно передавать сообщения на большие расстояния?',
        ['Телеграф', 'Печатный станок', 'Паровой двигатель'], 0,
        'Электрический телеграф стал важным шагом к современной связи.'),
      HistoryQuestion('Как называется всемирная компьютерная сеть, ставшая доступной широкой публике в 1990-х?',
        ['Интернет', 'Трансатлантический кабель', 'Радио'], 0,
        'В 1990-х интернет быстро вошёл в повседневную жизнь людей.'),
    ]),
];

class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  Era? selectedEra;
  int questionIndex = 0;
  int score = 0;
  int? selectedAnswer;
  bool answered = false;
  bool finished = false;
  bool exploring = false;
  Offset playerPosition = const Offset(.14, .55);
  bool traveling = false;
  final Set<int> completedQuestions = <int>{};
  int speechKey = 0;
  bool voiceEnabled = true;

  void speakQuestion() {
    if (!voiceEnabled || selectedEra == null) return;
    final question = selectedEra!.questions[questionIndex].text;
    try {
      web.window.speechSynthesis.cancel();
      final utterance = web.SpeechSynthesisUtterance(question)..lang = 'ru-RU'..rate = .91;
      web.window.speechSynthesis.speak(utterance);
    } catch (_) {
      // Some browsers do not expose speech synthesis.
    }
  }

  void startEra(Era era) => setState(() {
    selectedEra = era;
    questionIndex = 0;
    score = 0;
    selectedAnswer = null;
    answered = false;
    finished = false;
    exploring = true;
    playerPosition = const Offset(.14, .55);
    traveling = false;
    completedQuestions.clear();
    speechKey++;
  });

  void chooseAnswer(int index) {
    if (answered) return;
    setState(() {
      selectedAnswer = index;
      answered = true;
      if (index == selectedEra!.questions[questionIndex].answer && completedQuestions.add(questionIndex)) score++;
    });
  }

  void nextQuestion() => setState(() {
    if (selectedAnswer != selectedEra!.questions[questionIndex].answer) {
      selectedAnswer = null;
      answered = false;
      speechKey++;
      WidgetsBinding.instance.addPostFrameCallback((_) => speakQuestion());
      return;
    }
    if (completedQuestions.length == selectedEra!.questions.length) {
      finished = true;
    } else {
      selectedAnswer = null;
      answered = false;
      exploring = true;
      playerPosition = const Offset(.14, .55);
      traveling = false;
      speechKey++;
    }
  });

  Future<void> travelToQuestion(int index) async {
    if (traveling) return;
    final destinations = [
      const Offset(.30, .58),
      const Offset(.51, .39),
      const Offset(.72, .58),
    ];
    setState(() {
      questionIndex = index;
      selectedAnswer = null;
      answered = false;
      traveling = true;
      playerPosition = destinations[index];
    });
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    setState(() {
      traveling = false;
      exploring = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => speakQuestion());
  }

  void goHome() => setState(() {
    selectedEra = null;
    finished = false;
    selectedAnswer = null;
    answered = false;
  });

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
                child: selectedEra == null ? _buildHome(compact) :
                  (finished ? _buildResult(compact) : (exploring ? _buildWorld(compact) : _buildQuestion(compact))),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHome(bool compact) => Column(
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
        children: eras.map((era) => _EraButton(era: era, onTap: () => startEra(era))).toList()),
      const SizedBox(height: 18),
      const Text('Ответь на три вопроса и узнай, доволен ли тобой хранитель времени.',
        textAlign: TextAlign.center, style: TextStyle(color: Color(0xffa4adae), fontSize: 13)),
    ],
  );

  Widget _buildQuestion(bool compact) {
    final era = selectedEra!;
    final question = era.questions[questionIndex];
    return Column(
      children: [
        Row(children: [
          _IconButton(icon: Icons.arrow_back, onTap: goHome),
          const Spacer(),
          const _Brand(),
          const Spacer(),
          IconButton.filledTonal(
            tooltip: voiceEnabled ? 'Выключить озвучку' : 'Включить озвучку',
            onPressed: () => setState(() => voiceEnabled = !voiceEnabled),
            icon: Icon(voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
          ),
          Text('${questionIndex + 1} / ${era.questions.length}', style: _eyebrow),
        ]),
        SizedBox(height: compact ? 20 : 34),
        _MirrorCard(mood: answered ? (selectedAnswer == question.answer ? 'happy' : 'angry') : 'speaking',
          compact: compact,
          title: answered
            ? (selectedAnswer == question.answer ? 'МУДРО!' : 'ХМ…')
            : 'СЛУШАЙ ВРЕМЯ',
          subtitle: answered
            ? (selectedAnswer == question.answer ? 'Зеркало довольно\nтвоим ответом.' : 'Зеркало нахмурилось,\nно историю не обманешь.')
            : 'Зеркало задаёт\nвопрос из эпохи:'),
        const SizedBox(height: 18),
        _ProgressBar(value: (questionIndex + (answered ? 1 : 0)) / era.questions.length, color: era.color),
        const SizedBox(height: 18),
        Text('${era.name.toUpperCase()}  ·  ${era.years}', style: TextStyle(fontSize: 11, letterSpacing: 2.2, color: era.color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _SpeakingQuestion(key: ValueKey(speechKey), text: question.text,
          compact: compact, onFinished: () {}),
        const SizedBox(height: 18),
        ...List.generate(question.options.length, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _AnswerButton(label: question.options[index], index: index,
            correct: question.answer == index, selected: selectedAnswer == index,
          answered: answered, onTap: () => chooseAnswer(index)),
        )),
        if (answered) ...[
          const SizedBox(height: 4),
          Text(question.fact, textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xffc1c6c2), height: 1.4, fontSize: 13)),
          const SizedBox(height: 14),
          _PrimaryButton(label: selectedAnswer == question.answer
              ? (questionIndex + 1 == era.questions.length ? 'ЗАВЕРШИТЬ ПУТЕШЕСТВИЕ' : 'ОТКРЫТЬ СЛЕДУЮЩИЙ ПУТЬ')
              : 'ПОПРОБОВАТЬ ЕЩЁ РАЗ',
            onTap: nextQuestion),
        ],
      ],
    );
  }

  Widget _buildWorld(bool compact) {
    final era = selectedEra!;
    return Column(children: [
      Row(children: [
        _IconButton(icon: Icons.arrow_back, onTap: goHome),
        const Spacer(),
        const _Brand(),
        const Spacer(),
        IconButton.filledTonal(
          tooltip: voiceEnabled ? 'Выключить озвучку' : 'Включить озвучку',
          onPressed: () => setState(() => voiceEnabled = !voiceEnabled),
          icon: Icon(voiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
        ),
      ]),
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
            CustomPaint(painter: _WorldPainter(color: era.color)),
            Positioned(left: w * .77, top: h * .18, width: w * .13, height: h * .39,
              child: _WorldMirror(glowing: true, color: era.color)),
            AnimatedPositioned(duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic,
              left: playerPosition.dx * w - 22, top: playerPosition.dy * h - 30,
              child: _WorldHero(color: era.color)),
            Positioned(left: 14, top: 14, child: _MapBadge(icon: Icons.person, text: 'ПУТЕШЕСТВЕННИК')),
            ...List.generate(era.questions.length, (index) {
              const points = [Offset(.30, .58), Offset(.51, .39), Offset(.72, .58)];
              const icons = [Icons.castle_outlined, Icons.menu_book_rounded, Icons.auto_awesome];
              final point = points[index];
              return Positioned(left: w * point.dx - 23, top: h * point.dy - 23,
                child: _QuestionMarker(index: index, complete: completedQuestions.contains(index),
                  color: era.color, icon: icons[index], disabled: traveling,
                  onTap: () => travelToQuestion(index)));
            }),
            if (traveling) Positioned(left: 0, right: 0, bottom: 20,
              child: Center(child: _MapBadge(icon: Icons.directions_walk, text: 'ИДЁМ К ВОПРОСУ'))),
          ]);
        }))),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center,
        children: List.generate(era.questions.length, (index) => _MapQuestionChip(
          index: index, complete: completedQuestions.contains(index), color: era.color,
          onTap: traveling ? null : () => travelToQuestion(index))),
      ),
      const SizedBox(height: 8),
      Text('${completedQuestions.length} из ${era.questions.length} вопросов открыто',
        textAlign: TextAlign.center, style: const TextStyle(color: Color(0xffb4b8b4), fontSize: 12)),
    ]);
  }

  Widget _buildResult(bool compact) {
    final ratio = score / selectedEra!.questions.length;
    final mood = ratio >= .67 ? 'happy' : (ratio == 0 ? 'angry' : 'curious');
    final headline = ratio == 1 ? 'ИСТИННЫЙ ЗНАТОК!' : (ratio >= .67 ? 'ОТЛИЧНЫЙ ПУТЬ!' : 'ПУТЕШЕСТВИЕ ПРОДОЛЖАЕТСЯ');
    final message = ratio == 1 ? 'Зеркало сияет: ты прекрасно знаешь эту эпоху.' :
      (ratio >= .67 ? 'Хранитель времени доволен. Ещё немного — и все тайны раскрыты.' :
      'Зеркало советует заглянуть в учебник и попробовать ещё раз.');
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(children: [_IconButton(icon: Icons.arrow_back, onTap: goHome), const Spacer(), const _Brand(), const Spacer(), const SizedBox(width: 44)]),
      const SizedBox(height: 26),
      _MirrorCard(mood: mood, compact: compact, title: headline, subtitle: message),
      const SizedBox(height: 20),
      Text('$score из ${selectedEra!.questions.length}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xffe2b47b))),
      const SizedBox(height: 5),
      Text('правильных ответов · ${selectedEra!.name}', style: const TextStyle(color: Color(0xffa4adae))),
      const SizedBox(height: 22),
      _PrimaryButton(label: 'ВЫБРАТЬ ДРУГУЮ ЭПОХУ', onTap: goHome),
      const SizedBox(height: 10),
      TextButton(onPressed: () => startEra(selectedEra!), child: const Text('ПРОЙТИ ЕЩЁ РАЗ')),
    ]);
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
  const _WorldPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final background = Paint()..shader = const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xff29413d), Color(0xff1b302e), Color(0xff263936)],
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

    final bush = Paint()..color = const Color(0xff142722).withValues(alpha: .78);
    final bushHighlight = Paint()..color = const Color(0xff54765c).withValues(alpha: .36);
    final clusters = <Offset>[
      Offset(size.width * .12, size.height * .23), Offset(size.width * .27, size.height * .24),
      Offset(size.width * .43, size.height * .19), Offset(size.width * .57, size.height * .22),
      Offset(size.width * .90, size.height * .21), Offset(size.width * .91, size.height * .72),
      Offset(size.width * .37, size.height * .83), Offset(size.width * .14, size.height * .83),
    ];
    for (final p in clusters) {
      canvas.drawCircle(p, 18, bush);
      canvas.drawCircle(p.translate(-5, -4), 8, bushHighlight);
      canvas.drawCircle(p.translate(8, -1), 9, bushHighlight);
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

  @override
  bool shouldRepaint(covariant _WorldPainter oldDelegate) => oldDelegate.color != color;
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
  const _MirrorCard({required this.mood, required this.title, required this.subtitle, required this.compact});
  final String mood;
  final String title;
  final String subtitle;
  final bool compact;
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
          child: _AnimatedFace(mood: mood, size: compact ? 70 : 86),
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
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));

  @override
  void initState() {
    super.initState();
    _blink.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (mounted) _blink.reverse();
        });
      }
    });
    _scheduleBlink();
  }

  Future<void> _scheduleBlink() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      if (mounted && widget.mood != 'angry') _blink.forward(from: 0);
    }
  }

  @override
  void dispose() {
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
                _Eye(size: d * .12, angry: angry, blink: _blink.value),
                SizedBox(width: d * .13),
                _Eye(size: d * .12, angry: angry, blink: _blink.value),
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
  const _EraButton({required this.era, required this.onTap});
  final Era era;
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

