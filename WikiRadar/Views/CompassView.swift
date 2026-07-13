import SwiftUI

struct CompassView: View {
  @Environment(AppModel.self) private var model
  let article: Article

  var body: some View {
    VStack(spacing: 0) {
      Text(article.title)
        .font(.footnote.bold())
        .lineLimit(2)
        .multilineTextAlignment(.center)
      dial
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      Text(model.formattedDistance(to: article))
        .font(.title3.bold())
    }
    .padding(.horizontal, 4)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("compass-view")
    .onAppear { model.locationService.startHeading() }
    .onDisappear { model.locationService.stopHeading() }
  }

  private var heading: Double? { model.locationService.heading }
  private var hasFix: Bool { model.locationService.location != nil }

  private var dial: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
      Canvas { context, size in
        drawDial(context: context, size: size, date: timeline.date)
      }
    }
    .overlay { statusOverlay }
  }

  @ViewBuilder private var statusOverlay: some View {
    Group {
      if !hasFix {
        Text("Waiting for GPS…")
      } else if !model.locationService.headingSupported {
        Text("Compass unavailable\non this watch")
      } else if heading == nil {
        Text("Calibrating:\ntilt in a figure 8")
      }
    }
    .font(.footnote)
    .multilineTextAlignment(.center)
    .foregroundStyle(.secondary)
  }

  /// Radar dial: expanding ping ring, rotating rose with cardinal letters,
  /// and a bearing arrow — a port of the Pebble compass window.
  private func drawDial(context: GraphicsContext, size: CGSize, date: Date) {
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    let radius = min(size.width, size.height) / 2 - 2
    guard radius > 10 else { return }
    // The rose rotates with the heading so N marks north on screen
    let rotation = -(heading ?? 0) * .pi / 180

    // Radar ping: a ring sweeps to the dial edge, then rests until the
    // next 4-second cycle
    let phase = date.timeIntervalSinceReferenceDate
      .truncatingRemainder(dividingBy: 4)
    let sweepSeconds = 1.2
    if phase < sweepSeconds {
      let progress = phase / sweepSeconds
      let pingRadius = radius * progress
      let pingRect = CGRect(x: center.x - pingRadius,
                            y: center.y - pingRadius,
                            width: pingRadius * 2, height: pingRadius * 2)
      context.stroke(Path(ellipseIn: pingRect),
                     with: .color(.cyan.opacity(0.7 * (1 - progress))),
                     lineWidth: 2)
    }

    // Dial ring
    let dialRect = CGRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
    context.stroke(Path(ellipseIn: dialRect),
                   with: .color(.gray.opacity(0.6)), lineWidth: 2)

    // Rose: cardinal letters every 90°, minor ticks every 30°
    let cardinals = ["N", "E", "S", "W"]
    for i in 0..<12 {
      let angle = rotation + Double(i) * .pi / 6
      let sinA = sin(angle)
      let cosA = cos(angle)
      if i % 3 == 0 {
        let letterRadius = radius - 12
        let position = CGPoint(x: center.x + sinA * letterRadius,
                               y: center.y - cosA * letterRadius)
        let letter = Text(cardinals[i / 3])
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(i == 0 ? Color.cyan : Color.gray)
        context.draw(letter, at: position)
      } else {
        var tick = Path()
        tick.move(to: CGPoint(x: center.x + sinA * (radius - 6),
                              y: center.y - cosA * (radius - 6)))
        tick.addLine(to: CGPoint(x: center.x + sinA * (radius - 2),
                                 y: center.y - cosA * (radius - 2)))
        context.stroke(tick, with: .color(.gray.opacity(0.6)), lineWidth: 1)
      }
    }

    guard let heading,
          let location = model.locationService.location else { return }

    let bearing = GeoMath.bearing(from: location.coordinate,
                                  to: article.coordinate)
    let arrowAngle = (bearing - heading) * .pi / 180
    let arrow = arrowPath(center: center, radius: radius, angle: arrowAngle)
    context.fill(arrow, with: .color(.cyan))
    context.stroke(arrow, with: .color(.black), lineWidth: 1)
  }

  /// The Pebble arrow outline, drawn for a radius-58 dial and scaled to
  /// ours; `angle` is radians clockwise from screen-up.
  private func arrowPath(center: CGPoint, radius: CGFloat,
                         angle: Double) -> Path {
    let base: [CGPoint] = [
      CGPoint(x: 0, y: -38), CGPoint(x: 19, y: 3), CGPoint(x: 7, y: 3),
      CGPoint(x: 7, y: 35), CGPoint(x: -7, y: 35), CGPoint(x: -7, y: 3),
      CGPoint(x: -19, y: 3),
    ]
    let scale = radius / 58
    let sinA = CGFloat(sin(angle))
    let cosA = CGFloat(cos(angle))
    var path = Path()
    for (index, point) in base.enumerated() {
      let x = point.x * scale
      let y = point.y * scale
      let rotated = CGPoint(x: center.x + x * cosA - y * sinA,
                            y: center.y + x * sinA + y * cosA)
      if index == 0 {
        path.move(to: rotated)
      } else {
        path.addLine(to: rotated)
      }
    }
    path.closeSubpath()
    return path
  }
}
