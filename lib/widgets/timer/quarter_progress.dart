import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scorecard/services/game_state_service.dart';

class QuarterProgress extends StatelessWidget {
  const QuarterProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateService>(
      builder: (context, gameStateService, child) {
        final currentQuarter = gameStateService.selectedQuarter;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
          ),
          child: Row(
            children: List.generate(4, (index) {
              final quarterNumber = index + 1;
              final isCurrentQuarter = quarterNumber == currentQuarter;
              final isCompleted = quarterNumber < currentQuarter;

              return Expanded(
                child: Container(
                  margin:
                      index < 3
                          ? const EdgeInsets.only(right: 4)
                          : EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isCurrentQuarter
                            ? Theme.of(context).colorScheme.primaryContainer
                            : isCompleted
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius:
                        quarterNumber == 1
                            ? const BorderRadius.only(
                              topLeft: Radius.circular(12.0),
                              bottomLeft: Radius.circular(12.0),
                            )
                            : quarterNumber == 4
                            ? const BorderRadius.only(
                              topRight: Radius.circular(12.0),
                              bottomRight: Radius.circular(12.0),
                            )
                            : BorderRadius.zero,
                  ),
                  child: Text(
                    'Q$quarterNumber',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color:
                          isCurrentQuarter
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : isCompleted
                              ? Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer
                              : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight:
                          isCurrentQuarter ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
