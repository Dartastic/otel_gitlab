// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_gitlab_suppression.dart';

const _tracerName = 'dartastic_otel_libs_gitlab';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a GitLab REST API call (e.g. `projects.get`,
/// `merge_requests.create`) in a CLIENT span.
Future<T> tracedGitlab<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? projectId,
  String? host,
}) async {
  if (gitlabInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'gitlab.resource': resource,
    'gitlab.action': action,
    'gitlab.operation': '$resource.$action',
  };
  if (projectId != null) m['gitlab.project.id'] = projectId;
  if (host != null) m['gitlab.host'] = host;

  final span = _tracer().startSpan(
    'gitlab $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
