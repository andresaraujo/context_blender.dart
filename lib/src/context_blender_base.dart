library context_blender.base;

import 'dart:math' as math;
import 'dart:html' as dom;

enum BlendMode {
  NORMAL,
  SRC_OVER,
  SCREEN,
  MULTIPLY,
  DIFFERENCE,
  SRC_IN,
  PLUS,
  ADD,
  OVERLAY,
  HARDLIGHT,
  COLORDODGE,
  DODGE,
  COLORBURN,
  BURN,
  DARKEN,
  DARKER,
  LIGHTEN,
  LIGHTER,
  EXCLUSION,
  SOFTLIGHT,
  LUMINOSITY,
  COLOR,
  HUE,
  SATURATION,
  LIGHTERCOLOR,
  DARKERCOLOR
}

class Blender {
  int fSoftlight(int a, int b) {
    /*
				http://en.wikipedia.org/wiki/Blend_modes#Soft_Light
				2ab+a^2 (1-2b), if b<0.5
				2a(1-b) +sqrt(a)(2b-1), otherwise
			*/
    int b2 = b << 1;
    if (b < 128) return (a * (b2 + (a * (255 - b2) >> 8))) >> 8;
    else return (a * (511 - b2) + (math.sqrt(a << 8) * (b2 - 255))).toInt() >> 8;
  }

  int fOverlay(int a, int b) {
    return a < 128
    ? (a * b) >> 7
    : // (2*a*b)>>8 :
    255 - (((255 - b) * (255 - a)) >> 7);
  }

  int fDodge(int a, int b) {
    return (b == 255 && a == 0) ? 255 : math.min(255, (a << 8) / (255 - b));
  }

  int fBurn(int a, int b) {
    return (b == 255 && a == 0) ? 0 : 255 - math.min(255, ((255 - a) << 8) / b);
  }

  /*
			// yyy = similar to YCbCr
			0.2990    0.5870    0.1140
			-0.1687   -0.3313    0.5000
			0.5000   -0.4187   -0.0813
		*/
  Map<String, double> rgb2YCbCr(r, g, b) {
    return {
      'r': 0.2990 * r + 0.5870 * g + 0.1140 * b,
      'g': -0.1687 * r - 0.3313 * g + 0.5000 * b,
      'b': 0.5000 * r - 0.4187 * g - 0.0813 * b
    };
  }

  /*
			1.0000   -0.0000    1.4020
			1.0000   -0.3441   -0.7141
			1.0000    1.7720    0.0000
		*/
  Map<String, double> YCbCr2rgb(r, g, b) {
    return {
      'r': r + 1.4020 * b,
      'g': r - 0.3441 * g - 0.7141 * b,
      'b': r + 1.7720 * g
    };
  }

  Map<String, double> rgb2hsv(r, g, b) {
    var c = rgb2YCbCr(r, g, b);
    var s = math.sqrt(c['g'] * c['g'] + c['b'] * c['b']),
    h = math.atan2(c['g'], c['b']);
    return {'h': h, s: s, 'v': c['r']};
  }

  Map<String, double> hsv2rgb(h, s, v) {
    var g = s * math.sin(h),
    b = s * math.cos(h);
    return YCbCr2rgb(v, g, b);
  }

  blend(dom.CanvasElement fromCanvas, dom.CanvasElement destCanvas,
        BlendMode blendMode, {num destX: 0, num destY: 0, num sourceX: 0,
        num sourceY: 0, num width: 0, num height: 0}) {
    if (width == 0) width = fromCanvas.width;
    if (height == 0) height = fromCanvas.height;

    width = math.min(
        math.min(width, fromCanvas.width - sourceX), destCanvas.width - destX);
    height = math.min(math.min(height, fromCanvas.height - sourceY),
    destCanvas.height - destY);

    var srcD =
    fromCanvas.context2D.getImageData(sourceX, sourceY, width, height);
    var dstD = destCanvas.context2D.getImageData(destX, destY, width, height);

    List<int> src = srcD.data;
    List<int> dst = dstD.data;

    double sA, dA;
    int len = dst.length;
    double sRA, sGA, sBA, dRA, dGA, dBA, dA2;
    int r1, g1, b1, r2, g2, b2;
    double demultiply;

    for (int px = 0; px < len; px += 4) {
      sA = src[px + 3] / 255;
      dA = dst[px + 3] / 255;
      dA2 = (sA + dA - sA * dA);
      dst[px + 3] = (dA2 * 255).toInt();

      r1 = dst[px];
      g1 = dst[px + 1];
      b1 = dst[px + 2];
      r2 = src[px];
      g2 = src[px + 1];
      b2 = src[px + 2];

      sRA = r2 / 255 * sA;
      dRA = r1 / 255 * dA;
      sGA = g2 / 255 * sA;
      dGA = g1 / 255 * dA;
      sBA = b2 / 255 * sA;
      dBA = b1 / 255 * dA;

      demultiply = 255 / dA2;

      double f1 = dA * sA;
      double f2 = dA - f1;
      double f3 = sA - f1;

      switch (blendMode) {
        case BlendMode.NORMAL:
        case BlendMode.SRC_OVER:
          dst[px] = ((sRA + dRA - dRA * sA) * demultiply).toInt();
          dst[px + 1] = ((sGA + dGA - dGA * sA) * demultiply).toInt();
          dst[px + 2] = ((sBA + dBA - dBA * sA) * demultiply).toInt();
          break;
        case BlendMode.SCREEN:
          dst[px] = ((sRA + dRA - sRA * dRA) * demultiply).toInt();
          dst[px + 1] = ((sGA + dGA - sGA * dGA) * demultiply).toInt();
          dst[px + 2] = ((sBA + dBA - sBA * dBA) * demultiply).toInt();
          break;
        case BlendMode.MULTIPLY:
          dst[px] = ((sRA * dRA + sRA * (1 - dA) + dRA * (1 - sA)) * demultiply)
          .toInt();
          dst[px + 1] = ((sGA * dGA + sGA * (1 - dA) + dGA * (1 - sA)) *
          demultiply).toInt();
          dst[px + 2] = ((sBA * dBA + sBA * (1 - dA) + dBA * (1 - sA)) *
          demultiply).toInt();
          break;
        case BlendMode.DIFFERENCE:
          dst[px] = ((sRA + dRA - 2 * math.min(sRA * dA, dRA * sA)) *
          demultiply).toInt();
          dst[px + 1] = ((sGA + dGA - 2 * math.min(sGA * dA, dGA * sA)) *
          demultiply).toInt();
          dst[px + 2] = ((sBA + dBA - 2 * math.min(sBA * dA, dBA * sA)) *
          demultiply).toInt();
          break;

      // ******* Slightly different from Photoshop, where alpha is concerned
        case BlendMode.SRC_IN:
          dA2 = sA * dA;
          demultiply = 255 / dA2;
          dst[px] = (sRA * dA * demultiply).toInt();
          dst[px + 1] = (sGA * dA * demultiply).toInt();
          dst[px + 2] = (sBA * dA * demultiply).toInt();
          dst[px + 3] = (dA2 * 255).toInt();
          break;
        case BlendMode.PLUS:
        case BlendMode.ADD:
        // Photoshop doesn't simply add the alpha channels; this might be correct wrt SVG 1.2
          dst[px] = (math.min(sRA + dRA, 1) * demultiply).toInt();
          dst[px + 1] = (math.min(sGA + dGA, 1) * demultiply).toInt();
          dst[px + 2] = (math.min(sBA + dBA, 1) * demultiply).toInt();
          break;
        case BlendMode.OVERLAY:
          dst[px] = (f1 * fOverlay(r1, r2) + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * fOverlay(g1, g2) + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * fOverlay(b1, b2) + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.HARDLIGHT: // hardlight(a,b) = overlay(b,a)
          dst[px] = (f1 * fOverlay(r2, r1) + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * fOverlay(g2, g1) + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * fOverlay(b2, b1) + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.COLORDODGE:
        case BlendMode.DODGE:
          dst[px] = (f1 * fDodge(r1, r2) + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * fDodge(g1, g2) + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * fDodge(b1, b2) + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.COLORBURN:
        case BlendMode.BURN:
          dst[px] = (f1 * fBurn(r1, r2) + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * fBurn(g1, g2) + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * fBurn(b1, b2) + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.DARKEN:
        case BlendMode.DARKER:
          dst[px] = (f1 * (r1 < r2 ? r1 : r2) + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * (g1 < g2 ? g1 : g2) + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * (b1 < b2 ? b1 : b2) + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.LIGHTEN:
        case BlendMode.LIGHTER:
          dst[px] = ((sRA < dRA ? dRA : sRA) * demultiply).toInt();
          dst[px + 1] = ((sGA < dGA ? dGA : sGA) * demultiply).toInt();
          dst[px + 2] = ((sBA < dBA ? dBA : sBA) * demultiply).toInt();
          break;
        case BlendMode.EXCLUSION:
          dst[px] = ((dRA + sRA - 2 * dRA * sRA) * demultiply).toInt();
          dst[px + 1] = ((dGA + sGA - 2 * dGA * sGA) * demultiply).toInt();
          dst[px + 2] = ((dBA + sBA - 2 * dBA * sBA) * demultiply).toInt();
          break;
        case BlendMode.SOFTLIGHT:
          dst[px] = (f1 * fSoftlight(r1, r2) + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * fSoftlight(g1, g2) + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * fSoftlight(b1, b2) + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.LUMINOSITY:
          var hsl = rgb2YCbCr(r1, g1, b1);
          var hsl2 = rgb2YCbCr(r2, g2, b2);
          var rgb = YCbCr2rgb(hsl2['r'], hsl['g'], hsl['b']);
          dst[px] = (f1 * rgb['r'] + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * rgb['g'] + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * rgb['b'] + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.COLOR:
          var hsl = rgb2YCbCr(r1, g1, b1);
          var hsl2 = rgb2YCbCr(r2, g2, b2);
          var rgb = YCbCr2rgb(hsl['r'], hsl2['g'], hsl2['b']);
          dst[px] = (f1 * rgb['r'] + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * rgb['g'] + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * rgb['b'] + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.HUE:
          var hsl = rgb2hsv(r1, g1, b1);
          var hsl2 = rgb2hsv(r2, g2, b2);
          var rgb = hsv2rgb(hsl2['h'], hsl['s'], hsl['v']);
          dst[px] = (f1 * rgb['r'] + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * rgb['g'] + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * rgb['b'] + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.SATURATION:
          var hsl = rgb2hsv(r1, g1, b1);
          var hsl2 = rgb2hsv(r2, g2, b2);
          var rgb = hsv2rgb(hsl['h'], hsl2['s'], hsl['v']);
          dst[px] = (f1 * rgb['r'] + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * rgb['g'] + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * rgb['b'] + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.LIGHTERCOLOR:
          var rgb = 2.623 * (r1 - r2) + 5.15 * (g1 - g2) + b1 - b2 > 0
          ? {'r': r1, 'g': g1, 'b': b1}
          : {'r': r2, 'g': g2, 'b': b2};
          dst[px] = (f1 * rgb['r'] + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * rgb['g'] + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * rgb['b'] + f2 * b1 + f3 * b2).toInt();
          break;
        case BlendMode.DARKERCOLOR:
          var rgb = 2.623 * (r1 - r2) + 5.15 * (g1 - g2) + b1 - b2 < 0
          ? {'r': r1, 'g': g1, 'b': b1}
          : {'r': r2, 'g': g2, 'b': b2};
          dst[px] = (f1 * rgb['r'] + f2 * r1 + f3 * r2).toInt();
          dst[px + 1] = (f1 * rgb['g'] + f2 * g1 + f3 * g2).toInt();
          dst[px + 2] = (f1 * rgb['b'] + f2 * b1 + f3 * b2).toInt();
          break;
      }
    }
    destCanvas.context2D.putImageData(dstD, destX, destY);
  }

  const Blender();
}