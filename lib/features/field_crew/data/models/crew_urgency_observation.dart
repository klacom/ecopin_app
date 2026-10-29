const crewUrgencyLabels = {
  'urgent_observed': 'Urgency observed',
  'conditions_differ': 'Conditions differ',
  'unable_to_verify': 'Unable to verify',
};

Map<String, dynamic> crewUrgencyNote({
  required String taskId,
  required String observerId,
  required int assignmentGeneration,
  required int reportClaimGeneration,
  required String result,
  required String conditions,
}) {
  if (!crewUrgencyLabels.containsKey(result) ||
      conditions.trim().length < 3 ||
      conditions.trim().length > 1500) {
    throw ArgumentError(
      'Choose an observation and describe conditions (3-1500 characters).',
    );
  }
  return {
    'action_type': 'urgency_observation',
    'action':
        'On-site urgency: ${crewUrgencyLabels[result]}. ${conditions.trim()} [For officer review; no automatic trust change.]',
    'urgency_observation': {
      'task_id': taskId,
      'observer_id': observerId,
      'assignment_generation': assignmentGeneration,
      'report_claim_generation': reportClaimGeneration,
      'result': result,
      'conditions': conditions.trim(),
    },
  };
}
