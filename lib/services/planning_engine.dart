import '../models/planning_engine_request.dart';
import '../models/planning_response.dart';
import 'candidate_evaluator.dart';
import 'candidate_provider.dart';
import 'recommendation_candidate_provider.dart';

abstract interface class PlanningEngine {
  Future<PlanningResponse> createPlan(PlanningEngineRequest request);
}

class DefaultPlanningEngine implements PlanningEngine {
  const DefaultPlanningEngine({
    CandidateProvider provider = const RecommendationCandidateProvider(),
    CandidateEvaluator evaluator = const CandidateEvaluator(),
  })  : _provider = provider,
        _evaluator = evaluator;

  final CandidateProvider _provider;
  final CandidateEvaluator _evaluator;

  @override
  Future<PlanningResponse> createPlan(PlanningEngineRequest request) async {
    final candidates = await _provider.fetch(request);
    final evaluations = _evaluator.evaluateAll(candidates, request);
    final eligibleActivities = evaluations
        .where((evaluation) => evaluation.eligible)
        .map((evaluation) => evaluation.candidate.activity)
        .toList();

    return PlanningResponse.fromActivities(
      mode: request.mode,
      activities: eligibleActivities,
    );
  }
}
