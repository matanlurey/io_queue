// Copyright 2017, Google Inc.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:io_queue/io_queue.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  test('should work', () async {
    await d.dir('temp', [
      d.file('WELCOME', 'Hello World'),
    ]).create();
    final path = p.join(d.sandbox, 'temp', 'WELCOME');
    final queue = await IoQueue.roundRobin();
    expect(await queue.readAsString(path), 'Hello World');
  });
}
