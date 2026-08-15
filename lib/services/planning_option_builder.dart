import '../models/candidate_evaluation.dart';
import '../models/planning_engine_request.dart';
import '../models/planning_option.dart';
import '../models/planning_stop.dart';

class PlanningOptionBuilder {
  const PlanningOptionBuilder({
    this.maxOptions = 2,
    this.stopsPerOption = 2,
  });

  final int maxOptions;
  final int stopsPerOption;

  List<PlanningOption> build(
    Iterable<CandidateEvaluation> evaluations,
    PlanningEngineRequest request,
  ) {
    final available = evaluations
        .where((evaluation) => evaluation.eligible)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final options = <PlanningOption>[];
    final primaryFamilies = <String>{};
    var foodOptionUsed = false;

    while (available.isNotEmpty && options.length < maxOptions) {
      final anchorIndex = _anchorIndex(available, primaryFamilies);
      final selected = <CandidateEvaluation>[
        available.removeAt(anchorIndex),
      ];
      final anchorFamily = _family(selected.first);
      primaryFamilies.add(anchorFamily);

      while (selected.length < stopsPerOption && available.isNotEmpty) {
        final companionIndex = _companionIndex(
          available,
          selected,
          foodOptionUsed: foodOptionUsed,
        );
        if (companionIndex == null) break;
        selected.add(available.removeAt(companionIndex));
      }

      final ordered = _orderStops(selected);
      final containsFood = ordered.any((item) => _family(item) == 'food');
      foodOptionUsed = foodOptionUsed || containsFood;
      final optionNumber = options.length + 1;
      options.add(
        PlanningOption(
          id: 'option-$optionNumber',
          title: 'Option $optionNumber',
          summary: _summary(ordered, request),
          stops: [
            for (var index = 0; index < ordered.length; index++)
              PlanningStop(
                sequence: index,
                activity: ordered[index].candidate.activity,
              ),
          ],
        ),
      );
    }

    return options;
  }

  int _anchorIndex(
    List<CandidateEvaluation> available,
    Set<String> primaryFamilies,
  ) {
    final distinctIndex = available.indexWhere(
      (candidate) => !primaryFamilies.contains(_family(candidate)),
    );
    return distinctIndex < 0 ? 0 : distinctIndex;
  }

  int? _companionIndex(
    List<CandidateEvaluation> available,
    List<CandidateEvaluation> selected, {
    required bool foodOptionUsed,
  }) {
    final selectedFamilies = selected.map(_family).toSet();
    var bestIndex = -1;
    var bestScore = double.negativeInfinity;

    for (var index = 0; index < available.length; index++) {
      final candidate = available[index];
      final family = _family(candidate);
      if (family == 'food' &&
          (foodOptionUsed || selectedFamilies.contains('food'))) {
        continue;
      }

      var compatibility = candidate.score;
      if (!selectedFamilies.contains(family)) compatibility += 25;
      if (family == 'food' && !selectedFamilies.contains('food')) {
        compatibility += 12;
      }
      if (selectedFamilies.contains('event') && family != 'event') {
        compatibility += 10;
      }
      if (compatibility > bestScore) {
        bestScore = compatibility;
        bestIndex = index;
      }
    }

    return bestIndex < 0 ? null : bestIndex;
  }

  List<CandidateEvaluation> _orderStops(
    List<CandidateEvaluation> selected,
  ) {
    return [...selected]..sort((a, b) {
        final aFamily = _family(a);
        final bFamily = _family(b);
        if (aFamily == 'event' && bFamily != 'event') return -1;
        if (bFamily == 'event' && aFamily != 'event') return 1;
        if (aFamily == 'food' && bFamily != 'food') return 1;
        if (bFamily == 'food' && aFamily != 'food') return -1;
        return 0;
      });
  }

  String _summary(
    List<CandidateEvaluation> selected,
    PlanningEngineRequest request,
  ) {
    final families = selected.map(_family).toSet();
    if (families.contains('event')) return 'A live moment, made into an outing.';
    if (families.contains('food')) return 'Something to do, then something to savor.';
    if (request.constraints.energy?.toLowerCase() == 'high') {
      return 'An active plan with a change of pace.';
    }
    return 'Two complementary ways to make the time count.';
  }

  String _family(CandidateEvaluation evaluation) {
    final activity = evaluation.candidate.activity;
    final value = '${activity.category} ${activity.title}'.toLowerCase();
    if (_contains(value, const [
      'food',
      'restaurant',
      'dinner',
      'lunch',
      'breakfast',
      'coffee',
      'dessert',
      'bakery',
      'barbecue',
      'pizza',
    ])) {
      return 'food';
    }
    if (evaluation.candidate.kind.wireName == 'event') return 'event';
    if (_contains(value, const [
      'park',
      'beach',
      'outdoor',
      'garden',
      'trail',
      'scenic',
    ])) {
      return 'outdoors';
    }
    if (_contains(value, const [
      'museum',
      'gallery',
      'culture',
      'historic',
      'theater',
    ])) {
      return 'culture';
    }
    if (_contains(value, const [
      'sports',
      'fitness',
      'workout',
      'hiking',
      'kayak',
      'adventure',
      'basketball',
    ])) {
      return 'active';
    }
    if (_contains(value, const [
      'bowling',
      'arcade',
      'cinema',
      'movie',
      'comedy',
      'music',
      'entertainment',
      'mini golf',
    ])) {
      return 'entertainment';
    }
    return activity.category.toLowerCase().trim().isEmpty
        ? 'other'
        : activity.category.toLowerCase().trim();
  }

  bool _contains(String value, Iterable<String> tokens) {
    return tokens.any(value.contains);
  }
}
