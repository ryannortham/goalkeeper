import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/widgets/score_panel.dart';
import 'package:goalkeeper/widgets/score_table.dart';
import 'package:goalkeeper/widgets/timer.dart';

class Scoring extends StatefulWidget {
  const Scoring({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  ScoringState createState() => ScoringState();
}

class ScoringState extends State<Scoring> {
  late ScorePanelProvider scorePanelProvider;
  late GameSetupProvider gameSetupProvider;
  int _selectedIndex = 1;
  List<bool> isSelected = [true, false, false, false];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupProvider>(context);
    scorePanelProvider = Provider.of<ScorePanelProvider>(context);
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  double getProgressValue() {
    if (gameSetupProvider.quarterMSec <= 0 || scorePanelProvider.timerRawTime < 0) {
      return 0.0;
    }

    double progress = scorePanelProvider.timerRawTime / gameSetupProvider.quarterMSec;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return Consumer<GameSetupProvider>(
      builder: (context, scorePanelState, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: getProgressValue(),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8.0),
                ToggleButtons(
                  isSelected: List.generate(4, (index) => scorePanelProvider.selectedQuarter == index + 1),
                  onPressed: (index) {
                    scorePanelProvider.setSelectedQuarter(index + 1);
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Quarter 1'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Quarter 2'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Quarter 3'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Quarter 4'),
                    ),
                  ],
                ),
                const TimerWidget(),
                const SizedBox(height: 8.0),
                ScorePanel(
                  teamName: homeTeamName,
                  isHomeTeam: true,
                ),
                const ScoreTable(),
                ScorePanel(
                  teamName: awayTeamName,
                  isHomeTeam: false,
                ),
                const ScoreTable(),
              ],
            ),
          ),
        );
      },
    );
  }
}
