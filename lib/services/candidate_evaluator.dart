import '../models/candidate_evaluation.dart';
import '../models/planning_candidate.dart';
import '../models/planning_engine_request.dart';
import '../models/planning_mode.dart';

class CandidateEvaluator {
  const CandidateEvaluator();

  List<CandidateEvaluation> evaluateAll(
    Iterable<PlanningCandidate> candidates,
    PlanningEngineRequest request,
  ) {
    return candidates
        .map((candidate) => evaluate(candidate, request))
        .toList();
  }

  CandidateEvaluation evaluate(
    PlanningCandidate candidate,
    PlanningEngineRequest request,
  ) {
    final activity = candidate.activity;
    final searchable = [
      activity.title,
      activity.category,
      activity.description,
    ].join(' ').toLowerCase();
    final rejections = <String>[];
    final scoreReasons = <String>[];
    var score = 50.0;

    if (!candidate.isVerified) rejections.add('unverified');
    if (candidate.providerId.trim().isEmpty || activity.id.trim().isEmpty) {
      rejections.add('missing_provider_id');
    }
    if (activity.title.trim().isEmpty) rejections.add('missing_title');
    if (!_validCoordinate(activity.lat, activity.lng)) {
      rejections.add('invalid_location');
    }

    for (final exclusion in request.constraints.exclusions) {
      final normalized = exclusion.trim().toLowerCase();
      if (normalized.isNotEmpty && searchable.contains(normalized)) {
        rejections.add('excluded:$normalized');
      }
    }

    if (candidate.kind == CandidateKind.event) {
      final startsAt = activity.eventStart;
      if (startsAt == null) {
        score -= 8;
        scoreReasons.add('event_time_unknown');
      } else {
        if (request.startsAt != null && startsAt.isBefore(request.startsAt!)) {
          rejections.add('before_time_window');
        }
        if (request.endsAt != null && startsAt.isAfter(request.endsAt!)) {
          rejections.add('after_time_window');
        }
        score += 12;
        scoreReasons.add('scheduled_event');
      }
      if (candidate.sourceUrl?.isNotEmpty == true) {
        score += 5;
        scoreReasons.add('verified_source_link');
      }
    } else {
      score += 5;
      scoreReasons.add('permanent_place');
    }

    final budgetCap = _budgetCap(request.constraints.budget);
    if (budgetCap != null && activity.minPrice != null) {
      if (activity.minPrice! > budgetCap) {
        rejections.add('over_budget');
      } else {
        score += 8;
        scoreReasons.add('within_budget');
      }
    }

    final energyTokens = _energyTokens(request.constraints.energy);
    if (energyTokens.any(searchable.contains)) {
      score += 15;
      scoreReasons.add('energy_match');
    }

    final interests = request.constraints.interests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty);
    final interestMatches = interests.where(searchable.contains).length;
    if (interestMatches > 0) {
      score += interestMatches * 10;
      scoreReasons.add('interest_match');
    }

    final group = request.constraints.group?.toLowerCase() ?? '';
    if (group == 'family') {
      if (_containsAny(searchable, const ['nightclub', 'bar', 'casino'])) {
        score -= 25;
        scoreReasons.add('family_mismatch');
      } else {
        score += 5;
        scoreReasons.add('family_suitable');
      }
    }

    if (request.mode == PlanningMode.dateNight &&
        _containsAny(searchable, const [
          'romantic',
          'scenic',
          'gallery',
          'museum',
          'music',
          'dinner',
          'restaurant',
        ])) {
      score += 12;
      scoreReasons.add('date_night_match');
    }

    if (request.mode == PlanningMode.localEvents &&
        candidate.kind != CandidateKind.event) {
      rejections.add('not_an_event');
    }

    return CandidateEvaluation(
      candidate: candidate,
      eligible: rejections.isEmpty,
      score: score.clamp(0, 100).toDouble(),
      rejectionReasons: List.unmodifiable(rejections),
      scoreReasons: List.unmodifiable(scoreReasons),
    );
  }

  bool _validCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  bool _containsAny(String value, Iterable<String> tokens) {
    return tokens.any(value.contains);
  }

  List<String> _energyTokens(String? energy) {
    switch (energy?.toLowerCase()) {
      case 'low':
        return const [
          'restaurant',
          'coffee',
          'gallery',
          'museum',
          'culture',
          'theater',
        ];
      case 'medium':
        return const [
          'beach',
          'park',
          'outdoor',
          'market',
          'bowling',
          'mini golf',
        ];
      case 'high':
        return const [
          'fitness',
          'workout',
          'basketball',
          'sports',
          'adventure',
          'hiking',
          'kayak',
        ];
      default:
        return const [];
    }
  }

  double? _budgetCap(String? budget) {
    if (budget == null) return null;
    final normalized = budget.toLowerCase();
    if (normalized == 'free') return 0;
    if (normalized.contains('under')) {
      return _numbers(normalized).firstOrNull;
    }
    if (normalized.endsWith('+')) return null;
    final values = _numbers(normalized);
    return values.isEmpty ? null : values.last;
  }

  List<double> _numbers(String value) {
    return RegExp(r'\d+(?:\.\d+)?')
        .allMatches(value)
        .map((match) => double.parse(match.group(0)!))
        .toList();
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
