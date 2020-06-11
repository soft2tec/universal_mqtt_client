import 'package:test/test.dart';
import 'package:universal_mqtt_client/src/topics.dart';

void main() {
  test('wildcard matcher', () {
    expect(isTopicMatch('a/b/c/d', 'a/b/c/d'), equals(true));
    expect(isTopicMatch('+/b/c/d', 'a/b/c/d'), equals(true));
    expect(isTopicMatch('a/+/c/d', 'a/b/c/d'), equals(true));
    expect(isTopicMatch('a/+/+/d', 'a/b/c/d'), equals(true));
    expect(isTopicMatch('+/+/+/+', 'a/b/c/d'), equals(true));

    expect(isTopicMatch('a/b/c', 'a/b/c/d'), equals(false));
    expect(isTopicMatch('b/+/c/d', 'a/b/c/d'), equals(false));
    expect(isTopicMatch('+/+/+', 'a/b/c/d'), equals(false));

    expect(isTopicMatch('a/b/c/d', 'a/b/c'), equals(false));
    expect(isTopicMatch('a/b/c', 'a/d/c'), equals(false));

    expect(isTopicMatch('#', 'a/b/c/d'), equals(true));
    expect(isTopicMatch('a/#', 'a/b/c/d'), equals(true));
    expect(isTopicMatch('a/b/#', 'a/b/c/d'), equals(true));
    expect(isTopicMatch('a/b/c/#', 'a/b/c/d'), equals(true));
    expect(isTopicMatch('+/b/c/#', 'a/b/c/d'), equals(true));

    expect(isTopicMatch('#', '\$SYS/a/b'), equals(false));
    expect(isTopicMatch('+/a/b', '\$SYS/a/b'), equals(false));
    expect(isTopicMatch('\$SYS/#', '\$SYS/a/b'), equals(true));
    expect(isTopicMatch('\$SYS/+/b', '\$SYS/a/b'), equals(true));
    expect(isTopicMatch('\$SYS/+/c', '\$SYS/a/b'), equals(false));

    expect(isTopicMatch('a/b+/c/d', 'a/b1/c/d'), equals(false));
    expect(isTopicMatch('a/b+/c/d', 'a/b+/c/d'), equals(true));

    expect(
      () => isTopicMatch('#/b/c/d', 'a/b/c/d'),
      throwsA(predicate((e) =>
          e is InvalidTopicError &&
          e.message ==
              'The `#` wildcard must be in the last part of the topic.')),
    );
    expect(
      () => isTopicMatch('a/#/c/d', 'a/b/c/d'),
      throwsA(predicate((e) =>
          e is InvalidTopicError &&
          e.message ==
              'The `#` wildcard must be in the last part of the topic.')),
    );
    expect(
      () => isTopicMatch('a//c/d', 'a/b/c/d'),
      throwsA(predicate((e) =>
          e is InvalidTopicError &&
          e.message == 'A topic must not contain empty parts.')),
    );
    expect(
      () => isTopicMatch('a/b/c/', 'a/b/c/d'),
      throwsA(predicate((e) =>
          e is InvalidTopicError &&
          e.message == 'A topic must not contain empty parts.')),
    );
    expect(
      () => isTopicMatch('', 'a/b/c/d'),
      throwsA(predicate((e) =>
          e is InvalidTopicError &&
          e.message == 'A topic must not contain empty parts.')),
    );
  });
}
