// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library context_blender;

import 'dart:html' as dom;
import 'package:context_blender/context_blender.dart';

main() {
  var url1 =  "monocle-0.jpg";
  var url2 =  "monocle-1.jpg";

  var from = new dom.CanvasElement();
  var dest = new dom.CanvasElement();

  var img = new dom.ImageElement();

  var destImg =  dom.querySelector("#destImg") as dom.ImageElement;
  img.src = url1;
  img.onLoad.listen((_) {
    from.context2D.drawImage(img, 0, 0);

    var img2 = new dom.ImageElement();
    img2.src = url2;
    img2.onLoad.listen((_) {
      dest.context2D.drawImage(img2, 0, 0);

      blend(from, dest, BlendMode.DIFFERENCE);

      destImg.src = dest.toDataUrl();
    });
  });






}
