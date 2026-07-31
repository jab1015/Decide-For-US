import '../models/planning_candidate.dart';
import '../models/planning_engine_request.dart';

abstract interface class CandidateProvider {
  String get id;

  Future<List<PlanningCandidate>> fetch(PlanningEngineRequest request);
}
