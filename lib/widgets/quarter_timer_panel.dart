import 'package:flutter/material.dart';
import 'package:goalkeeper/providers/game_setup_provider.dart';
import 'package:goalkeeper/providers/score_panel_provider.dart';
import 'package:goalkeeper/widgets/timer.dart';
import 'package:goalkeeper/pages/scoring.dart';
import 'package:provider/provider.dart';

class QuarterTimerPanel extends StatefulWidget {
  final ValueNotifier<bool> isTimerRunning;

  const QuarterTimerPanel({
    super.key,
    required this.isTimerRunning,
  });

  @override
  State<QuarterTimerPanel> createState() => QuarterTimerPanelState();
}

class QuarterTimerPanelState extends State<QuarterTimerPanel> {
  final GlobalKey<TimerWidgetState> _timerKey = GlobalKey<TimerWidgetState>();

  // Expose method to reset timer from parent widgets
  void resetTimer() {
    _timerKey.currentState?.resetTimer();
  }

  // Expose method to start timer from parent widgets
  void startTimer() {
    final timerState = _timerKey.currentState;
    if (timerState != null && !timerState.isTimerActuallyRunning) {
      timerState.toggleTimer();
    }
  }

  double getProgressValue(GameSetupProvider gameSetupProvider,
      ScorePanelProvider scorePanelProvider) {
    if (gameSetupProvider.quarterMSec <= 0 ||
        scorePanelProvider.timerRawTime < 0) {
      return 0.0;
    }

    double progress =
        scorePanelProvider.timerRawTime / gameSetupProvider.quarterMSec;
    return progress.clamp(0.0, 1.0);
  }

  void _handleQuarterChange(
    int newQuarter,
    ScorePanelProvider scorePanelProvider,
  ) {
    final currentQuarter = scorePanelProvider.selectedQuarter;

    // If selecting the same quarter, do nothing
    if (newQuarter == currentQuarter) return;

    // Find parent ScoringState to record quarter end event
    final scoringState = context.findAncestorStateOfType<ScoringState>();
    if (scoringState != null) {
      // Record clock_end event for the previous quarter
      scoringState.recordQuarterEnd(currentQuarter);

      // If timer is running, pause it before changing quarters
      if (widget.isTimerRunning.value) {
        // Pause timer to ensure clean state for new quarter
        _timerKey.currentState?.toggleTimer();
      }
    }

    // Switch to the new quarter
    scorePanelProvider.setSelectedQuarter(newQuarter);

    // Reset the actual timer widget
    _timerKey.currentState?.resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Consumer2<GameSetupProvider, ScorePanelProvider>(
        builder: (context, gameSetupProvider, scorePanelProvider, _) {
          return Column(
            children: [
              // Quarter Selection
              ValueListenableBuilder<bool>(
                valueListenable: widget.isTimerRunning,
                builder: (context, isTimerRunning, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      style: SegmentedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: !isTimerRunning
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.38)
                            : Theme.of(context).colorScheme.onSurface,
                        disabledForegroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.38),
                        selectedForegroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        selectedBackgroundColor:
                            Theme.of(context).colorScheme.primary,
                      ),
                      segments: const [
                        ButtonSegment<int>(
                          value: 1,
                          label: Text('Q1'),
                        ),
                        ButtonSegment<int>(
                          value: 2,
                          label: Text('Q2'),
                        ),
                        ButtonSegment<int>(
                          value: 3,
                          label: Text('Q3'),
                        ),
                        ButtonSegment<int>(
                          value: 4,
                          label: Text('Q4'),
                        ),
                      ],
                      selected: {scorePanelProvider.selectedQuarter},
                      onSelectionChanged: (Set<int> newSelection) {
                        if (!isTimerRunning && newSelection.isNotEmpty) {
                          _handleQuarterChange(
                            newSelection.first,
                            scorePanelProvider,
                          );
                        }
                      },
                      multiSelectionEnabled: false,
                      emptySelectionAllowed: false,
                      showSelectedIcon: false,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8.0),

              // Timer Widget
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TimerWidget(
                      key: _timerKey, isRunning: widget.isTimerRunning),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
