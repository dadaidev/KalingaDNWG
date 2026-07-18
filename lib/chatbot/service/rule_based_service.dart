class RuleBasedService {
  static String getResponse(String userMessage) {
    final message = userMessage.toLowerCase().trim();

    if (_matchesAny(message, [
      'emergency',
      'overdose',
      'too much medicine',
      'trouble breathing',
      'chest pain',
      'hard to breathe',
    ])) {
      return '⚠️ If this is an emergency, please call your local emergency '
          'hotline right away or go to the nearest hospital.';
    }

    if (_matchesAny(message, [
      'hi',
      'hello',
      'hey',
      'good morning',
      'good evening',
    ])) {
      return 'Hello! I\'m your Medication Reminder Assistant. '
          'How can I help you today?';
    }

    if (_matchesAny(message, [
      'when',
      'what time',
      'schedule',
      'medication time',
      'dose time',
    ])) {
      return 'You can view your full medication schedule in the '
          '"My Medications" tab.';
    }

    if (_matchesAny(message, [
      'forgot',
      'missed',
      'didn\'t take',
      'skip',
      'skipped',
    ])) {
      return 'No worries. If you forgot to take your medication, do not '
          'double the dose. If it\'s almost time for the next scheduled '
          'dose, just wait for it instead. If you\'re unsure, it\'s best '
          'to talk to your doctor or pharmacist.';
    }

    if (_matchesAny(message, [
      'side effect',
      'allergy',
      'reaction',
      'adverse effect',
    ])) {
      return 'If you experience any unusual reaction after taking your '
          'medication, contact your doctor or pharmacist right away.';
    }

    if (_matchesAny(message, [
      'refill',
      'out of medicine',
      'running low',
      'no more medicine',
    ])) {
      return 'You can set up a refill reminder in the app\'s Settings.';
    }

    if (_matchesAny(message, ['thanks', 'thank you', 'salamat'])) {
      return 'You\'re welcome! I\'m here anytime you need help.';
    }

    if (_matchesAny(message, ['terms', 'conditions', 'privacy', 'policy'])) {
      return 'You can read the full Terms and Conditions in the '
          '"Terms & Conditions" section of the app.';
    }

    return 'Sorry, I didn\'t quite understand your question. '
        'You can try one of the following:\n\n'
        '• Medication schedule\n'
        '• Missed dose\n'
        '• Side effects\n'
        '• Medication refill';
  }

  static bool _matchesAny(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
}
