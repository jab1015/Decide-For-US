import '../models/planning_engine_request.dart';
import '../models/planning_response.dart';
import 'candidate_evaluator.dart';
import 'candidate_provider.dart';
import 'planning_option_builder.dart';
import 'recommendation_candidate_provider.dart';

abstract interface class PlanningEngine {
  Future<PlanningResponse> createPlan(PlanningEngineRequest request);
}

class DefaultPlanningEngine implements PlanningEngine {
  const DefaultPlanningEngine({
    CandidateProvider provider = const RecommendationCandidateProvider(),
    CandidateEvaluator evaluator = const CandidateEvaluator(),
    PlanningOptionBuilder optionBuilder = const PlanningOptionBuilder(),
  })  : _provider = provider,
        _evaluator = evaluator,
        _optionBuilder = optionBuilder;

  final CandidateProvider _provider;
  final CandidateEvaluator _evaluator;
  final PlanningOptionBuilder _optionBuilder;

  @override
  Future<PlanningResponse> createPlan(PlanningEngineRequest request) async {
    final candidates = await _provider.fetch(request);
    final evaluations = _evaluator.evaluateAll(candidates, request);
    final options = _optionBuilder.build(evaluations, request);

    return PlanningResponse(
      mode: request.mode,
      options: options,
      createdAt: DateTime.now().toUtc(),
    );
  }
}
