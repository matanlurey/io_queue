// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:isolate/isolate_runner.dart';
import 'package:pool/pool.dart';

/// Queue-based mulit-threaded File I/O using isolates.
///
/// There are a few typical ways of doing File I/O in Dart:
/// * Use synchronous File I/O, but it blocks them main thread.
/// * Use asynchronous File I/O, but has no maximum threads/files open.
/// * Use a [Pool] with asynchronous File I/O, but it doesn't reuse threads.
///
/// [IoQueue] is an experiment that combines a [Pool] with a user-implemented
/// asynchronous file I/O that uses a maximum number of threads and files open
/// for greater control, especially on resource constrained systems.
abstract class IoQueue {
  /// Creates a round-robin of [isolates] that are used for File I/O.
  ///
  /// Isolates are eagerly initialized, and terminated on [close].
  static Future<IoQueue> roundRobin([int isolates]) async {
    isolates ??= Platform.numberOfProcessors;
    final runners = new List.generate(isolates, (_) => IsolateRunner.spawn());
    return new _RoundRobinIoQueue(await Future.wait(runners));
  }

  /// Closes the queue and all pending reads/writes are cancelled.
  Future<Null> close();

  /// Returns the file contents of [path] as [utf8]-encoded String.
  Future<String> readAsString(String path);
}

class _RoundRobinIoQueue implements IoQueue {
  final List<IsolateRunner> _runners;
  int _pointer = 0;

  _RoundRobinIoQueue(this._runners);

  @override
  Future<Null> close() => Future
      .wait<dynamic>(_runners.map((runner) => runner.close()))
      .then((_) => null);

  IsolateRunner _next() {
    _pointer++;
    if (_pointer == _runners.length) {
      _pointer = 0;
    }
    return _runners[_pointer];
  }

  static String _readAsString(String path) {
    return new File(path).readAsStringSync();
  }

  @override
  Future<String> readAsString(String path) {
    return _next().run(_readAsString, path);
  }
}
