import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/widgets/game_details/game_info_card.dart';
import 'package:goalkeeper/widgets/game_details/game_score_section.dart';
import 'package:goalkeeper/widgets/game_details/live_game_title_builder.dart';
import 'package:goalkeeper/widgets/game_details/quarter_breakdown_section.dart';
import 'package:goalkeeper/widgets/scoring/score_table.dart';

/// Data source types for the game details widget
enum GameDataSource {
  /// Use a static GameRecord (for game history)
  /// This mode uses pre-saved game data from device storage
  staticData,

  /// Use live data from providers (for current game)
  /// This mode uses real-time data from ScorePanelProvider and GameSetupProvider
  liveData,
}

/// A unified widget for displaying game details that works with both
/// static game data (from history) and live data (from current game)
class GameDetailsWidget extends StatelessWidget {
  /// Static game data (used when dataSource is staticData)
  final GameRecord? staticGame;

  /// The data source to use
  final GameDataSource dataSource;

  /// Live game events (used when dataSource is liveData)
  final List<GameEvent>? liveEvents;

  /// Optional scroll controller
  final ScrollController? scrollController;

  const GameDetailsWidget({
    super.key,
    required this.dataSource,
    this.staticGame,
    this.liveEvents,
    this.scrollController,
  }) : assert(
            (dataSource == GameDataSource.staticData && staticGame != null) ||
                (dataSource == GameDataSource.liveData && liveEvents != null),
            'Must provide staticGame when using staticData or liveEvents when using liveData');

  /// Factory constructor for static data (game history)
  const GameDetailsWidget.fromStaticData({
    super.key,
    required GameRecord game,
    this.scrollController,
  })  : dataSource = GameDataSource.staticData,
        staticGame = game,
        liveEvents = null;

  /// Factory constructor for live data (current game)
  const GameDetailsWidget.fromLiveData({
    super.key,
    required List<GameEvent> events,
    this.scrollController,
  })  : dataSource = GameDataSource.liveData,
        staticGame = null,
        liveEvents = events;

  /// Determines if the game is complete based on timer events
  static bool isGameComplete(GameRecord game) {
    // If no events, it's definitely not complete
    if (game.events.isEmpty) return false;

    // PRIMARY CHECK: A game is complete if there's a clock_end event in quarter 4
    bool hasQ4ClockEnd =
        game.events.any((e) => e.quarter == 4 && e.type == 'clock_end');
    if (hasQ4ClockEnd) return true;

    // Not enough evidence to consider the game complete
    return false;
  }

  /// Gets the current quarter based on the latest events
  static int getCurrentQuarter(GameRecord game) {
    if (game.events.isEmpty) return 1;

    // Find the highest quarter number with events
    final maxQuarter =
        game.events.map((e) => e.quarter).reduce((a, b) => a > b ? a : b);
    return maxQuarter;
  }

  /// Builds a GameRecord from current provider data (for live data)
  GameRecord _buildGameFromProviders(BuildContext context) {
    final gameSetupAdapter = Provider.of<GameSetupAdapter>(context);
    final scorePanelAdapter = Provider.of<ScorePanelAdapter>(context);

    return GameRecord(
      id: 'current-game', // Temporary ID for current game
      date: gameSetupAdapter.gameDate,
      homeTeam: gameSetupAdapter.homeTeam,
      awayTeam: gameSetupAdapter.awayTeam,
      quarterMinutes: gameSetupAdapter.quarterMinutes,
      isCountdownTimer: gameSetupAdapter.isCountdownTimer,
      events: liveEvents ?? [],
      homeGoals: scorePanelAdapter.homeGoals,
      homeBehinds: scorePanelAdapter.homeBehinds,
      awayGoals: scorePanelAdapter.awayGoals,
      awayBehinds: scorePanelAdapter.awayBehinds,
    );
  }

  /// Builds a score table widget that correctly handles live vs static data
  Widget _buildScoreTable({
    required BuildContext context,
    required GameRecord game,
    required String displayTeam,
    required bool isHomeTeam,
  }) {
    if (dataSource == GameDataSource.liveData) {
      // For live data, use the existing ScorePanelAdapter from the widget tree
      // This ensures the score table shows real-time updates from the shared adapter
      // Use the live events instead of static game events
      return Consumer<ScorePanelAdapter>(
        builder: (context, scorePanelAdapter, child) {
          return ScoreTable(
            events: liveEvents ?? [], // Use live events for real-time updates
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            displayTeam: displayTeam,
            isHomeTeam: isHomeTeam,
            enabled: false, // Disable interactions in details view
            showHeader: false, // Hide team header
            showCounters: false, // Hide score counters
            isCompletedGame: false, // Live game is not completed
          );
        },
      );
    } else {
      // For static data, pass the current quarter directly to avoid provider listening
      final int currentQuarter = getCurrentQuarter(game);
      final bool isCompleted = isGameComplete(game);
      return ScoreTable(
        events: game.events,
        homeTeam: game.homeTeam,
        awayTeam: game.awayTeam,
        displayTeam: displayTeam,
        isHomeTeam: isHomeTeam,
        enabled: false, // Disable interactions in details view
        showHeader: false, // Hide team header
        showCounters: false, // Hide score counters
        currentQuarter:
            currentQuarter, // Pass quarter directly to avoid provider listening
        isCompletedGame:
            isCompleted, // Pass completion status to show all quarters
      );
    }
  }

  /// Builds the title for live games showing quarter and elapsed time
  String _buildLiveGameTitle(
      BuildContext context, ScorePanelAdapter scorePanelAdapter) {
    return LiveGameTitleBuilder.buildTitle(context, scorePanelAdapter);
  }

  @override
  Widget build(BuildContext context) {
    if (dataSource == GameDataSource.liveData) {
      // For live data, wrap in Consumer to rebuild when adapter data changes
      return Consumer2<GameSetupAdapter, ScorePanelAdapter>(
        builder: (context, gameSetupAdapter, scorePanelAdapter, child) {
          final GameRecord game = _buildGameFromProviders(context);
          return _buildGameDetailsContent(context, game);
        },
      );
    } else {
      // For static data, just use the provided game data
      final GameRecord game = staticGame!;
      return _buildGameDetailsContent(context, game);
    }
  }

  Widget _buildGameDetailsContent(BuildContext context, GameRecord game) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Info Card
          GameInfoCard(
            icon: Icons.sports_rugby,
            title: '${game.homeTeam} vs ${game.awayTeam}',
            content: Text(
              DateFormat('EEEE, MMM d, yyyy').format(game.date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          const SizedBox(height: 16),

          // Final Score Card
          dataSource == GameDataSource.liveData
              ? Consumer<ScorePanelAdapter>(
                  builder: (context, scorePanelAdapter, child) {
                    final liveTitle =
                        _buildLiveGameTitle(context, scorePanelAdapter);
                    return GameScoreSection(
                      game: game,
                      isLiveData: true,
                      liveTitleOverride: liveTitle,
                    );
                  },
                )
              : GameScoreSection(
                  game: game,
                  isLiveData: false,
                ),

          // Quarter Breakdown Card
          const SizedBox(height: 16),
          QuarterBreakdownSection(
            game: game,
            isLiveData: dataSource == GameDataSource.liveData,
            liveEvents: liveEvents,
            scoreTableBuilder: _buildScoreTable,
          ),
        ],
      ),
    );
  }
}

// Capturable game details functionality is now integrated into the main widget
// with the captureMode parameter
