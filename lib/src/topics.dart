class InvalidTopicError extends Error {
  final String message;
  InvalidTopicError(this.message);
  @override
  String toString() {
    return 'InvalidTopicError: $message';
  }
}

void assertValidTopic(String subscription) {
  final parts = subscription.split('/');
  for (var i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (part == '') {
      throw InvalidTopicError('A topic must not contain empty parts.');
    }
    if (part == '#') {
      if (i != parts.length - 1) {
        throw InvalidTopicError(
            'The `#` wildcard must be in the last part of the topic.');
      }
    }
  }
}

/// This function checks if the incoming topic matches the given matcher.
bool isTopicMatch(String matcher, String incoming) {
  // Check that there are no # anywhere but in the last part of the wildcard
  // and that no parts are empty.
  assertValidTopic(matcher);

  final matcherParts = matcher.split('/');
  final incomingParts = incoming.split('/');

  // Do not match topics starting with `$` with topics not starting with `$`.
  if (incomingParts.isNotEmpty &&
      incomingParts.first.startsWith('\$') &&
      matcherParts.isNotEmpty &&
      !matcherParts.first.startsWith('\$')) {
    return false;
  }

  // Check that the topics match in length, unless the last part of the matcher
  // is a # wildcard.
  if (matcherParts.length != incomingParts.length && matcherParts.last != '#') {
    return false;
  }

  for (var i = 0; i < matcherParts.length; i++) {
    final subPart = matcherParts[i];
    if (subPart == '#') return true;
    final inPart = incomingParts[i];
    if (subPart == inPart || subPart == '+') continue;
    return false;
  }
  return true;
}
