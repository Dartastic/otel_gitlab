// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_gitlab/otel_gitlab.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_gitlab-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('projects.get records CLIENT span', () async {
    await tracedGitlab<String>(
      resource: 'projects',
      action: 'get',
      projectId: '42',
      host: 'gitlab.com',
      invoke: () async => 'p',
    );
    final a = attrsOf(spans.findSpanByName('gitlab projects.get')!);
    expect(a['gitlab.resource'], 'projects');
    expect(a['gitlab.action'], 'get');
    expect(a['gitlab.operation'], 'projects.get');
    expect(a['gitlab.project.id'], '42');
    expect(a['gitlab.host'], 'gitlab.com');
  });

  test('suppression skips spans', () async {
    await runWithoutGitlabInstrumentationAsync(() async {
      await tracedGitlab<String>(
        resource: 'projects',
        action: 'get',
        invoke: () async => 'p',
      );
    });
    expect(spans.findSpansStartingWith('gitlab '), isEmpty);
  });
}
