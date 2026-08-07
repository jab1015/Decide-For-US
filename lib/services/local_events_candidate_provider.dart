import '../models/planning_candidate.dart';
import '../models/planning_engine_request.dart';
import '../models/planning_mode.dart';
import 'ai_service.dart';
import 'candidate_provider.dart';

class LocalEventsCandidateProvider implements CandidateProvider {
  const LocalEventsCandidateProvider();

  @override
  String get id => 'local_events';

  @override
  Future<List<PlanningCandidate>> fetch(PlanningEngineRequest request) async {
    if (request.mode != PlanningMode.localEvents) {
      throw ArgumentError.value(
        request.mode.wireName,
        'request.mode',
        'Local Events provider requires local_events mode.',
      );
    }

    final today = DateTime.now();
    final activities = await AIService.getLocalEvents(
      lat: request.origin.lat,
      lng: request.origin.lng,
      radiusMiles: request.constraints.radiusMiles,
      startDate: request.startsAt ?? today,
      endDate: request.endsAt ?? today.add(const Duration(days: 13)),
      group: request.constraints.group ?? 'Friends',
      budget: request.constraints.budget ?? r'$30–$75',
    );
    return activities.map(PlanningCandidate.fromActivity).toList();
  }
}
