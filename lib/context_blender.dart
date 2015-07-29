// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The context_blender library.
///
/// This is an awesome library. More dartdocs go here.
library context_blender;

import 'dart:html';
import 'src/context_blender_base.dart';

export 'src/context_blender_base.dart' show BlendMode;

const _blender = const Blender();

void blend(
    CanvasElement fromCanvas, CanvasElement destCanvas, BlendMode blendMode,
    {num destX: 0, num destY: 0, num sourceX: 0, num sourceY: 0, num width: 0,
    num height: 0}) {
  _blender.blend(fromCanvas, destCanvas, blendMode,
      destX: destY,
      destY: destY,
      sourceX: sourceX,
      sourceY: sourceY,
      width: width,
      height: height);
}
