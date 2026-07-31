import '../models/planning_engine_request.dart';
import '../models/planning_response.dart';
import 'candidate_provider.dart';
import 'recommendation_candidate_provider.dart';

abstract interface class PlanningEngine {
  Future<PlanningResponse> createPlan(PlanningEngineRequest request);
}

class DefaultPlanningEngine implements PlanningEngine {
  const DefaultPlanningEngine({
    CandidateProvider provider = const RecommendationCandidateProvider(),
  }) : _provider = provider;

  final CandidateProvider _provider;

  @override
  Future<PlanningResponse> createPlan(PlanningEngineRequest request) async {
    final candidates = await _provider.fetch(request);
    return PlanningResponse.fromActivities(
      mode: request.mode,
      activities: candidates.map((candidate) => candidate.activity).toList(),
    );
  }
}
