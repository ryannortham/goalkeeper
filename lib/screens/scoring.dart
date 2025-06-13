import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:goalkeeper/adapters/game_setup_adapter.dart';
import 'package:goalkeeper/adapters/score_panel_adapter.dart';
import 'package:goalkeeper/providers/game_record.dart';
import 'package:goalkeeper/services/game_history_service.dart';
import 'package:goalkeeper/services/game_state_service.dart';
import 'package:goalkeeper/services/screenshot_service.dart';
import 'package:goalkeeper/widgets/bottom_sheets/exit_game_bottom_sheet.dart';
import 'package:goalkeeper/widgets/scoring/scoring.dart';
import 'package:goalkeeper/widgets/timer/timer.dart';

import 'game_details.dart';
import 'game_history.dart';
import 'settings.dart';

class Scoring extends StatefulWidget {
  const Scoring({super.key, required this.title});
  final String title;

  @override
  ScoringState createState() => ScoringState();
}

class ScoringState extends State<Scoring> {
  late ScorePanelAdapter scorePanelProvider;
  late GameSetupAdapter gameSetupProvider;
  final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);
  List<bool> isSelected = [true, false, false, false];
  final GlobalKey<QuarterTimerPanelState> _quarterTimerKey =
      GlobalKey<QuarterTimerPanelState>();

  // Use the game state service directly
  final GameStateService _gameStateService = GameStateService.instance;
  bool _isClockRunning = false;

  // Share functionality - using screenshot service
  final ScreenshotService _screenshotService = ScreenshotService();
  bool _isSharing = false;
  bool _isSaving = false;

  Future<bool> _showExitConfirmation() async {
    return await ExitGameBottomSheet.show(context);
  }

  Future<bool> _onWillPop() async {
    // Always show exit confirmation when leaving an active game
    return await _showExitConfirmation();
  }

  /// Navigate to settings screen
  void _navigateToSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Settings(title: 'Settings'),
      ),
    );
    // No need to update game setup since quarter minutes and countdown timer
    // are no longer in settings - they're managed on the game setup screen
  }

  /// Navigate to game history screen
  void _navigateToGameHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameHistoryScreen(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameSetupProvider = Provider.of<GameSetupAdapter>(context);
    scorePanelProvider = Provider.of<ScorePanelAdapter>(context);

    // Sync local clock state with provider state
    _isClockRunning = scorePanelProvider.isTimerRunning;

    // Initialize the game if not already started
    if (_gameStateService.currentGameId == null) {
      _gameStateService.startNewGame();
    }
  }

  @override
  void initState() {
    super.initState();

    // Add listener to the timer running state to track clock events
    isTimerRunning.addListener(() {
      _onTimerRunningChanged(isTimerRunning.value);
    });
  }

  /// Track timer state changes
  void _onTimerRunningChanged(bool isRunning) {
    // Use post-frame callback to avoid setState during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isRunning && !_isClockRunning) {
        // Timer started
        _isClockRunning = true;
        scorePanelProvider.setTimerRunning(true);
      } else if (!isRunning && _isClockRunning) {
        // Timer paused
        _isClockRunning = false;
        scorePanelProvider.setTimerRunning(false);
      }
    });
  }

  /// Record end of quarter event
  /// This method is called from the QuarterTimerPanel when quarters change
  /// and from the timer widget when a quarter's time expires
  void recordQuarterEnd(int quarter) {
    _gameStateService.recordQuarterEnd(quarter);

    // Stop the timer and update provider state
    _isClockRunning = false;
    scorePanelProvider.setTimerRunning(false);

    // If this is the end of quarter 4, handle game completion
    if (quarter == 4) {
      _handleGameCompletion();
    }
  }

  // Public method that can be called by score counter when events change
  void updateGameAfterEventChange() {
    // The game state service handles automatic saving
    // This method now does nothing as the service handles saving automatically
  }

  /// Check if the game is completed (Q4 has ended)
  bool _isGameComplete() {
    return _gameStateService.isGameComplete();
  }

  /// Handle game completion by navigating to game details screen
  void _handleGameCompletion() {
    // Only navigate once when game is complete
    if (_isGameComplete()) {
      // Use post-frame callback to avoid during-build navigation issues
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final String? gameId = _gameStateService.currentGameId;
        if (gameId == null) {
          debugPrint(
              'No current game ID found. Cannot navigate to game details.');
          return;
        }

        // CRITICAL FIX: Ensure final save completes before resetting
        // Force immediate save of the completed game before resetting state
        await _gameStateService.forceFinalSave();

        // Load all saved games and find the one with the matching ID
        // Since we now preserve the game ID, it should be found reliably
        final allGames = await GameHistoryService.loadGames();
        final gameRecord = allGames.firstWhere(
          (game) => game.id == gameId,
          orElse: () {
            // Fallback: find the most recent game with matching teams
            final homeTeam = gameSetupProvider.homeTeam;
            final awayTeam = gameSetupProvider.awayTeam;
            debugPrint(
                'Could not find game with ID $gameId, using fallback search');
            return allGames.firstWhere(
              (game) => game.homeTeam == homeTeam && game.awayTeam == awayTeam,
            );
          },
        );

        // Reset the game state AFTER ensuring save is complete
        // This ensures a clean state for the next game setup
        _gameStateService.resetGame();

        // Navigate to game details page passing the saved game record
        if (!mounted) return;

        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GameDetailsPage(game: gameRecord),
          ),
        );
      });
    }
  }

  // Access game events from the game state service
  List<GameEvent> get gameEvents => _gameStateService.gameEvents;

  @override
  void dispose() {
    isTimerRunning.dispose();
    super.dispose();
  }

  void _shareGameDetails(BuildContext context) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final gameSetupAdapter =
          Provider.of<GameSetupAdapter>(context, listen: false);
      final scorePanelAdapter =
          Provider.of<ScorePanelAdapter>(context, listen: false);

      final shareText = _buildShareText();

      // Use the screenshot service to share live game details
      await _screenshotService.shareLiveGameDetails(
        homeTeam: gameSetupAdapter.homeTeam,
        awayTeam: gameSetupAdapter.awayTeam,
        gameDate: gameSetupAdapter.gameDate,
        quarterMinutes: gameSetupAdapter.quarterMinutes,
        isCountdownTimer: gameSetupAdapter.isCountdownTimer,
        events: _gameStateService.gameEvents,
        homeGoals: scorePanelAdapter.homeGoals,
        homeBehinds: scorePanelAdapter.homeBehinds,
        awayGoals: scorePanelAdapter.awayGoals,
        awayBehinds: scorePanelAdapter.awayBehinds,
        shareText: shareText,
        themeData: Theme.of(context),
      );
    } catch (e) {
      debugPrint('Error sharing game details: $e');
      // Show error if sharing failed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void saveGameImage(BuildContext context) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final gameSetupAdapter =
          Provider.of<GameSetupAdapter>(context, listen: false);
      final scorePanelAdapter =
          Provider.of<ScorePanelAdapter>(context, listen: false);

      // Use the screenshot service to save live game to gallery
      await _screenshotService.saveLiveGameToGallery(
        homeTeam: gameSetupAdapter.homeTeam,
        awayTeam: gameSetupAdapter.awayTeam,
        gameDate: gameSetupAdapter.gameDate,
        quarterMinutes: gameSetupAdapter.quarterMinutes,
        isCountdownTimer: gameSetupAdapter.isCountdownTimer,
        events: _gameStateService.gameEvents,
        homeGoals: scorePanelAdapter.homeGoals,
        homeBehinds: scorePanelAdapter.homeBehinds,
        awayGoals: scorePanelAdapter.awayGoals,
        awayBehinds: scorePanelAdapter.awayBehinds,
        themeData: Theme.of(context),
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Game image saved to gallery'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      // Show error if saving failed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _buildShareText() {
    final gameSetupAdapter =
        Provider.of<GameSetupAdapter>(context, listen: false);
    final scorePanelAdapter =
        Provider.of<ScorePanelAdapter>(context, listen: false);

    final homeScore =
        '${scorePanelAdapter.homeGoals}.${scorePanelAdapter.homeBehinds} (${scorePanelAdapter.homePoints})';
    final awayScore =
        '${scorePanelAdapter.awayGoals}.${scorePanelAdapter.awayBehinds} (${scorePanelAdapter.awayPoints})';

    return '''${gameSetupAdapter.homeTeam} vs ${gameSetupAdapter.awayTeam}
Score: $homeScore - $awayScore
Date: ${gameSetupAdapter.gameDate.day}/${gameSetupAdapter.gameDate.month}/${gameSetupAdapter.gameDate.year}''';
  }

  @override
  Widget build(BuildContext context) {
    String homeTeamName = gameSetupProvider.homeTeam;
    String awayTeamName = gameSetupProvider.awayTeam;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Consumer<GameSetupAdapter>(
        builder: (context, scorePanelState, _) {
          return Scaffold(
            appBar: AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  '$homeTeamName vs $awayTeamName',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  tooltip: 'Save Game Image',
                  onPressed: () {
                    saveGameImage(context);
                  },
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Menu',
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                  ),
                ),
              ],
            ),
            endDrawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.sports_rugby,
                          size: 32,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'GoalKeeper',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Menu',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      _navigateToSettings();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Game History'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      _navigateToGameHistory();
                    },
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Timer Panel Card
                    Card(
                      elevation: 1,
                      child: QuarterTimerPanel(
                          key: _quarterTimerKey,
                          isTimerRunning: isTimerRunning),
                    ),
                    const SizedBox(height: 4),

                    // Home Team Score Table
                    ValueListenableBuilder<bool>(
                      valueListenable: isTimerRunning,
                      builder: (context, timerRunning, child) {
                        return Consumer<ScorePanelAdapter>(
                          builder: (context, scorePanelAdapter, child) {
                            return Card(
                              elevation: 1,
                              child: ScoreTable(
                                events: List<GameEvent>.from(
                                    gameEvents), // Create a defensive copy
                                homeTeam: homeTeamName,
                                awayTeam: awayTeamName,
                                displayTeam: homeTeamName,
                                isHomeTeam: true,
                                enabled: timerRunning,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 4),

                    // Away Team Score Table
                    ValueListenableBuilder<bool>(
                      valueListenable: isTimerRunning,
                      builder: (context, timerRunning, child) {
                        return Consumer<ScorePanelAdapter>(
                          builder: (context, scorePanelAdapter, child) {
                            return Card(
                              elevation: 1,
                              child: ScoreTable(
                                events: List<GameEvent>.from(
                                    gameEvents), // Create a defensive copy
                                homeTeam: homeTeamName,
                                awayTeam: awayTeamName,
                                displayTeam: awayTeamName,
                                isHomeTeam: false,
                                enabled: timerRunning,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _isSharing ? null : () => _shareGameDetails(context),
              tooltip: 'Share Game Details',
              child: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
            ),
          );
        },
      ),
    );
  }
}
