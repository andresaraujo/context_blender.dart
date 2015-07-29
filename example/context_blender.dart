// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library context_blender;

import 'dart:html' as dom;
import 'package:context_blender/context_blender.dart';

main() async {
  var from = new dom.CanvasElement();
  var dest = new dom.CanvasElement();

  var img = new dom.ImageElement();
  var img2 = new dom.ImageElement();

  var destImg =  dom.querySelector("#destImg") as dom.ImageElement;

  img.src = "monocle-0.jpg";
  img2.src = "monocle-1.jpg";

  await img.onLoad.first;
  await img2.onLoad.first;

  from.context2D.drawImage(img, 0, 0);
  dest.context2D.drawImage(img2, 0, 0);

  blend(from, dest, BlendMode.DIFFERENCE);
  destImg.src = dest.toDataUrl();
}
