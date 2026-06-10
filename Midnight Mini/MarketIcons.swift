import SwiftUI

// All icons are custom SwiftUI Shapes / drawings. No SF Symbols, no emoji.

// A simple shopping bag / store-front mark used as the brand icon.
struct StoreMarkIcon: View {
    var size: CGFloat = 28
    var color: Color = MarketTheme.neonAmber
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            // awning
            let awning = Path { p in
                p.move(to: CGPoint(x: w*0.10, y: h*0.34))
                p.addLine(to: CGPoint(x: w*0.90, y: h*0.34))
                p.addLine(to: CGPoint(x: w*0.82, y: h*0.50))
                p.addLine(to: CGPoint(x: w*0.18, y: h*0.50))
                p.closeSubpath()
            }
            ctx.fill(awning, with: .color(color))
            // store body
            let body = Path(roundedRect: CGRect(x: w*0.18, y: h*0.50, width: w*0.64, height: h*0.40), cornerRadius: w*0.04)
            ctx.fill(body, with: .color(color.opacity(0.55)))
            // door
            let door = Path(roundedRect: CGRect(x: w*0.42, y: h*0.60, width: w*0.16, height: h*0.30), cornerRadius: w*0.02)
            ctx.fill(door, with: .color(MarketTheme.nightDeep))
            // little moon above
            let moon = Path(ellipseIn: CGRect(x: w*0.62, y: h*0.06, width: w*0.22, height: w*0.22))
            ctx.fill(moon, with: .color(color.opacity(0.9)))
            let bite = Path(ellipseIn: CGRect(x: w*0.56, y: h*0.05, width: w*0.20, height: w*0.20))
            ctx.fill(bite, with: .color(MarketTheme.night))
        }
        .frame(width: size, height: size)
    }
}

// Coin icon for money displays.
struct CoinIcon: View {
    var size: CGFloat = 18
    var color: Color = MarketTheme.money
    var body: some View {
        Canvas { ctx, sz in
            let r = CGRect(x: sz.width*0.06, y: sz.height*0.06, width: sz.width*0.88, height: sz.height*0.88)
            ctx.fill(Path(ellipseIn: r), with: .color(color))
            let inner = r.insetBy(dx: sz.width*0.16, dy: sz.height*0.16)
            ctx.stroke(Path(ellipseIn: inner), with: .color(MarketTheme.nightDeep.opacity(0.7)), lineWidth: max(1, sz.width*0.06))
            // dollar bar
            var bar = Path()
            bar.move(to: CGPoint(x: sz.width*0.5, y: sz.height*0.26))
            bar.addLine(to: CGPoint(x: sz.width*0.5, y: sz.height*0.74))
            ctx.stroke(bar, with: .color(MarketTheme.nightDeep.opacity(0.7)), lineWidth: max(1, sz.width*0.08))
        }
        .frame(width: size, height: size)
    }
}

// A box/crate icon for backroom stock.
struct CrateIcon: View {
    var size: CGFloat = 22
    var color: Color = MarketTheme.neonCyan
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let box = Path(roundedRect: CGRect(x: w*0.12, y: h*0.22, width: w*0.76, height: h*0.62), cornerRadius: w*0.05)
            ctx.fill(box, with: .color(color.opacity(0.85)))
            // lid line
            var lid = Path()
            lid.move(to: CGPoint(x: w*0.12, y: h*0.40))
            lid.addLine(to: CGPoint(x: w*0.88, y: h*0.40))
            ctx.stroke(lid, with: .color(MarketTheme.nightDeep.opacity(0.6)), lineWidth: max(1, w*0.05))
            // cross strap
            var v = Path()
            v.move(to: CGPoint(x: w*0.5, y: h*0.40))
            v.addLine(to: CGPoint(x: w*0.5, y: h*0.84))
            ctx.stroke(v, with: .color(MarketTheme.nightDeep.opacity(0.5)), lineWidth: max(1, w*0.05))
        }
        .frame(width: size, height: size)
    }
}

// Up-arrow chevron for upgrades.
struct UpgradeIcon: View {
    var size: CGFloat = 22
    var color: Color = MarketTheme.neonViolet
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            var p = Path()
            p.move(to: CGPoint(x: w*0.18, y: h*0.58))
            p.addLine(to: CGPoint(x: w*0.5, y: h*0.26))
            p.addLine(to: CGPoint(x: w*0.82, y: h*0.58))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: max(2, w*0.10), lineCap: .round, lineJoin: .round))
            var p2 = Path()
            p2.move(to: CGPoint(x: w*0.18, y: h*0.78))
            p2.addLine(to: CGPoint(x: w*0.5, y: h*0.46))
            p2.addLine(to: CGPoint(x: w*0.82, y: h*0.78))
            ctx.stroke(p2, with: .color(color.opacity(0.6)), style: StrokeStyle(lineWidth: max(2, w*0.10), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// Bar-chart-ish stats icon (NOT the Charts framework — just drawn bars).
struct StatsIcon: View {
    var size: CGFloat = 22
    var color: Color = MarketTheme.neonGreen
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let heights: [CGFloat] = [0.4, 0.7, 0.5, 0.9]
            for (i, hh) in heights.enumerated() {
                let x = w*0.16 + CGFloat(i)*w*0.18
                let bh = h*0.66*hh
                let rect = CGRect(x: x, y: h*0.82 - bh, width: w*0.12, height: bh)
                ctx.fill(Path(roundedRect: rect, cornerRadius: w*0.03), with: .color(color.opacity(0.5 + 0.12*Double(i))))
            }
        }
        .frame(width: size, height: size)
    }
}

// A clock for the shift timer.
struct ClockIcon: View {
    var size: CGFloat = 18
    var color: Color = MarketTheme.neonCyan
    var body: some View {
        Canvas { ctx, sz in
            let r = CGRect(x: sz.width*0.08, y: sz.height*0.08, width: sz.width*0.84, height: sz.height*0.84)
            ctx.stroke(Path(ellipseIn: r), with: .color(color), lineWidth: max(1.5, sz.width*0.08))
            var hands = Path()
            hands.move(to: CGPoint(x: sz.width*0.5, y: sz.height*0.5))
            hands.addLine(to: CGPoint(x: sz.width*0.5, y: sz.height*0.26))
            hands.move(to: CGPoint(x: sz.width*0.5, y: sz.height*0.5))
            hands.addLine(to: CGPoint(x: sz.width*0.68, y: sz.height*0.58))
            ctx.stroke(hands, with: .color(color), style: StrokeStyle(lineWidth: max(1.5, sz.width*0.08), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

// A small person silhouette for customers / clerk.
struct PersonIcon: View {
    var size: CGFloat = 22
    var color: Color = MarketTheme.textHi
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let head = Path(ellipseIn: CGRect(x: w*0.36, y: h*0.14, width: w*0.28, height: w*0.28))
            ctx.fill(head, with: .color(color))
            var body = Path()
            body.move(to: CGPoint(x: w*0.5, y: h*0.46))
            body.addArc(center: CGPoint(x: w*0.5, y: h*0.92), radius: w*0.30, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            ctx.fill(body, with: .color(color.opacity(0.92)))
        }
        .frame(width: size, height: size)
    }
}

// Heart icon for patience / mood.
struct HeartIcon: View {
    var size: CGFloat = 16
    var color: Color = MarketTheme.neonPink
    var filled: Bool = true
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            var p = Path()
            p.move(to: CGPoint(x: w*0.5, y: h*0.82))
            p.addCurve(to: CGPoint(x: w*0.06, y: h*0.34),
                       control1: CGPoint(x: w*0.18, y: h*0.66),
                       control2: CGPoint(x: w*0.06, y: h*0.50))
            p.addArc(center: CGPoint(x: w*0.28, y: h*0.30), radius: w*0.22, startAngle: .degrees(160), endAngle: .degrees(0), clockwise: false)
            p.addArc(center: CGPoint(x: w*0.72, y: h*0.30), radius: w*0.22, startAngle: .degrees(180), endAngle: .degrees(20), clockwise: false)
            p.addCurve(to: CGPoint(x: w*0.5, y: h*0.82),
                       control1: CGPoint(x: w*0.94, y: h*0.50),
                       control2: CGPoint(x: w*0.82, y: h*0.66))
            p.closeSubpath()
            if filled {
                ctx.fill(p, with: .color(color))
            } else {
                ctx.stroke(p, with: .color(color), lineWidth: max(1, w*0.08))
            }
        }
        .frame(width: size, height: size)
    }
}

// X / close mark.
struct CloseIcon: View {
    var size: CGFloat = 18
    var color: Color = MarketTheme.textMid
    var body: some View {
        Canvas { ctx, sz in
            var p = Path()
            p.move(to: CGPoint(x: sz.width*0.24, y: sz.height*0.24))
            p.addLine(to: CGPoint(x: sz.width*0.76, y: sz.height*0.76))
            p.move(to: CGPoint(x: sz.width*0.76, y: sz.height*0.24))
            p.addLine(to: CGPoint(x: sz.width*0.24, y: sz.height*0.76))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: max(1.5, sz.width*0.09), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

// Product glyph rendered from a small style enum (each product line gets a look).
enum ProductGlyph {
    case bottle, snack, coffee, magazine, sandwich, candy, iceCream, lottery, batteries, energy
    case hotDog, slushie, flowers, charger, plushie

    func draw(in ctx: inout GraphicsContext, size sz: CGSize, color: Color) {
        let w = sz.width, h = sz.height
        switch self {
        case .bottle:
            var p = Path()
            p.move(to: CGPoint(x: w*0.42, y: h*0.14))
            p.addLine(to: CGPoint(x: w*0.58, y: h*0.14))
            p.addLine(to: CGPoint(x: w*0.58, y: h*0.30))
            p.addLine(to: CGPoint(x: w*0.66, y: h*0.42))
            p.addLine(to: CGPoint(x: w*0.66, y: h*0.86))
            p.addLine(to: CGPoint(x: w*0.34, y: h*0.86))
            p.addLine(to: CGPoint(x: w*0.34, y: h*0.42))
            p.addLine(to: CGPoint(x: w*0.42, y: h*0.30))
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
            ctx.fill(Path(CGRect(x: w*0.34, y: h*0.56, width: w*0.32, height: h*0.16)), with: .color(MarketTheme.nightDeep.opacity(0.4)))
        case .snack:
            let r = Path(roundedRect: CGRect(x: w*0.22, y: h*0.20, width: w*0.56, height: h*0.60), cornerRadius: w*0.10)
            ctx.fill(r, with: .color(color))
            var z = Path()
            z.move(to: CGPoint(x: w*0.30, y: h*0.36))
            z.addLine(to: CGPoint(x: w*0.70, y: h*0.36))
            z.move(to: CGPoint(x: w*0.30, y: h*0.64))
            z.addLine(to: CGPoint(x: w*0.70, y: h*0.64))
            ctx.stroke(z, with: .color(MarketTheme.nightDeep.opacity(0.4)), lineWidth: max(1, w*0.04))
        case .coffee:
            let cup = Path(roundedRect: CGRect(x: w*0.28, y: h*0.30, width: w*0.40, height: h*0.50), cornerRadius: w*0.05)
            ctx.fill(cup, with: .color(color))
            let lid = Path(roundedRect: CGRect(x: w*0.24, y: h*0.22, width: w*0.48, height: h*0.10), cornerRadius: w*0.03)
            ctx.fill(lid, with: .color(color.opacity(0.7)))
            var steam = Path()
            steam.move(to: CGPoint(x: w*0.5, y: h*0.18))
            steam.addLine(to: CGPoint(x: w*0.5, y: h*0.08))
            ctx.stroke(steam, with: .color(color.opacity(0.6)), lineWidth: max(1, w*0.05))
        case .magazine:
            let r = Path(roundedRect: CGRect(x: w*0.24, y: h*0.18, width: w*0.52, height: h*0.64), cornerRadius: w*0.03)
            ctx.fill(r, with: .color(color))
            var lines = Path()
            for i in 0..<3 {
                let y = h*0.34 + CGFloat(i)*h*0.16
                lines.move(to: CGPoint(x: w*0.32, y: y))
                lines.addLine(to: CGPoint(x: w*0.68, y: y))
            }
            ctx.stroke(lines, with: .color(MarketTheme.nightDeep.opacity(0.4)), lineWidth: max(1, w*0.04))
        case .sandwich:
            var top = Path()
            top.addArc(center: CGPoint(x: w*0.5, y: h*0.46), radius: w*0.28, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            top.closeSubpath()
            ctx.fill(top, with: .color(color))
            ctx.fill(Path(CGRect(x: w*0.22, y: h*0.46, width: w*0.56, height: h*0.10)), with: .color(MarketTheme.neonGreen.opacity(0.7)))
            ctx.fill(Path(roundedRect: CGRect(x: w*0.22, y: h*0.54, width: w*0.56, height: h*0.16), cornerRadius: w*0.04), with: .color(color.opacity(0.85)))
        case .candy:
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.34, y: h*0.34, width: w*0.32, height: h*0.32)), with: .color(color))
            var lw = Path()
            lw.move(to: CGPoint(x: w*0.34, y: h*0.50))
            lw.addLine(to: CGPoint(x: w*0.16, y: h*0.40))
            lw.addLine(to: CGPoint(x: w*0.16, y: h*0.60))
            lw.closeSubpath()
            lw.move(to: CGPoint(x: w*0.66, y: h*0.50))
            lw.addLine(to: CGPoint(x: w*0.84, y: h*0.40))
            lw.addLine(to: CGPoint(x: w*0.84, y: h*0.60))
            lw.closeSubpath()
            ctx.fill(lw, with: .color(color.opacity(0.8)))
        case .iceCream:
            var cone = Path()
            cone.move(to: CGPoint(x: w*0.34, y: h*0.46))
            cone.addLine(to: CGPoint(x: w*0.66, y: h*0.46))
            cone.addLine(to: CGPoint(x: w*0.5, y: h*0.86))
            cone.closeSubpath()
            ctx.fill(cone, with: .color(MarketTheme.neonAmber.opacity(0.8)))
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.30, y: h*0.20, width: w*0.40, height: h*0.34)), with: .color(color))
        case .lottery:
            let r = Path(roundedRect: CGRect(x: w*0.22, y: h*0.28, width: w*0.56, height: h*0.40), cornerRadius: w*0.04)
            ctx.fill(r, with: .color(color))
            var star = Path()
            let cx = w*0.5, cy = h*0.48, rad = w*0.12
            for i in 0..<5 {
                let a = -CGFloat.pi/2 + CGFloat(i)*2*CGFloat.pi/5
                let pt = CGPoint(x: cx + cos(a)*rad, y: cy + sin(a)*rad)
                if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
            }
            star.closeSubpath()
            ctx.fill(star, with: .color(MarketTheme.nightDeep.opacity(0.5)))
        case .batteries:
            let r = Path(roundedRect: CGRect(x: w*0.30, y: h*0.20, width: w*0.40, height: h*0.58), cornerRadius: w*0.04)
            ctx.fill(r, with: .color(color))
            ctx.fill(Path(CGRect(x: w*0.42, y: h*0.14, width: w*0.16, height: h*0.08)), with: .color(color))
            var bolt = Path()
            bolt.move(to: CGPoint(x: w*0.52, y: h*0.30))
            bolt.addLine(to: CGPoint(x: w*0.42, y: h*0.50))
            bolt.addLine(to: CGPoint(x: w*0.50, y: h*0.50))
            bolt.addLine(to: CGPoint(x: w*0.46, y: h*0.68))
            bolt.addLine(to: CGPoint(x: w*0.58, y: h*0.46))
            bolt.addLine(to: CGPoint(x: w*0.50, y: h*0.46))
            bolt.closeSubpath()
            ctx.fill(bolt, with: .color(MarketTheme.nightDeep.opacity(0.6)))
        case .energy:
            let r = Path(roundedRect: CGRect(x: w*0.34, y: h*0.18, width: w*0.32, height: h*0.62), cornerRadius: w*0.05)
            ctx.fill(r, with: .color(color))
            var bolt = Path()
            bolt.move(to: CGPoint(x: w*0.54, y: h*0.26))
            bolt.addLine(to: CGPoint(x: w*0.42, y: h*0.52))
            bolt.addLine(to: CGPoint(x: w*0.50, y: h*0.52))
            bolt.addLine(to: CGPoint(x: w*0.46, y: h*0.72))
            bolt.addLine(to: CGPoint(x: w*0.60, y: h*0.46))
            bolt.addLine(to: CGPoint(x: w*0.52, y: h*0.46))
            bolt.closeSubpath()
            ctx.fill(bolt, with: .color(MarketTheme.nightDeep.opacity(0.55)))
        case .hotDog:
            // bun
            let bun = Path(roundedRect: CGRect(x: w*0.14, y: h*0.40, width: w*0.72, height: h*0.26), cornerRadius: h*0.13)
            ctx.fill(bun, with: .color(MarketTheme.neonAmber.opacity(0.85)))
            // sausage
            let dog = Path(roundedRect: CGRect(x: w*0.18, y: h*0.44, width: w*0.64, height: h*0.16), cornerRadius: h*0.08)
            ctx.fill(dog, with: .color(color))
            // mustard zigzag
            var zig = Path()
            zig.move(to: CGPoint(x: w*0.24, y: h*0.52))
            var x = w*0.24
            var up = true
            while x < w*0.78 {
                x += w*0.10
                zig.addLine(to: CGPoint(x: x, y: up ? h*0.48 : h*0.56))
                up.toggle()
            }
            ctx.stroke(zig, with: .color(MarketTheme.neonGreen.opacity(0.9)), style: StrokeStyle(lineWidth: max(1, w*0.04), lineCap: .round, lineJoin: .round))
        case .slushie:
            // cup (trapezoid)
            var cup = Path()
            cup.move(to: CGPoint(x: w*0.30, y: h*0.40))
            cup.addLine(to: CGPoint(x: w*0.70, y: h*0.40))
            cup.addLine(to: CGPoint(x: w*0.62, y: h*0.86))
            cup.addLine(to: CGPoint(x: w*0.38, y: h*0.86))
            cup.closeSubpath()
            ctx.fill(cup, with: .color(color.opacity(0.85)))
            // domed ice
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.28, y: h*0.22, width: w*0.44, height: h*0.30)), with: .color(color))
            // straw
            var straw = Path()
            straw.move(to: CGPoint(x: w*0.56, y: h*0.10))
            straw.addLine(to: CGPoint(x: w*0.48, y: h*0.44))
            ctx.stroke(straw, with: .color(MarketTheme.neonPink), style: StrokeStyle(lineWidth: max(1, w*0.06), lineCap: .round))
        case .flowers:
            // stem
            var stem = Path()
            stem.move(to: CGPoint(x: w*0.5, y: h*0.86))
            stem.addLine(to: CGPoint(x: w*0.5, y: h*0.46))
            ctx.stroke(stem, with: .color(MarketTheme.neonGreen.opacity(0.8)), style: StrokeStyle(lineWidth: max(1, w*0.05), lineCap: .round))
            // petals
            let cx = w*0.5, cy = h*0.36, pr = w*0.12
            for i in 0..<5 {
                let a = -CGFloat.pi/2 + CGFloat(i)*2*CGFloat.pi/5
                let px = cx + cos(a)*pr, py = cy + sin(a)*pr
                ctx.fill(Path(ellipseIn: CGRect(x: px - w*0.09, y: py - w*0.09, width: w*0.18, height: w*0.18)), with: .color(color))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: cx - w*0.07, y: cy - w*0.07, width: w*0.14, height: w*0.14)), with: .color(MarketTheme.neonAmber))
        case .charger:
            // body
            let body = Path(roundedRect: CGRect(x: w*0.30, y: h*0.30, width: w*0.40, height: h*0.40), cornerRadius: w*0.06)
            ctx.fill(body, with: .color(color))
            // prongs
            ctx.fill(Path(CGRect(x: w*0.40, y: h*0.16, width: w*0.06, height: h*0.16)), with: .color(color.opacity(0.8)))
            ctx.fill(Path(CGRect(x: w*0.54, y: h*0.16, width: w*0.06, height: h*0.16)), with: .color(color.opacity(0.8)))
            // bolt
            var bolt = Path()
            bolt.move(to: CGPoint(x: w*0.54, y: h*0.38))
            bolt.addLine(to: CGPoint(x: w*0.44, y: h*0.52))
            bolt.addLine(to: CGPoint(x: w*0.52, y: h*0.52))
            bolt.addLine(to: CGPoint(x: w*0.46, y: h*0.64))
            bolt.addLine(to: CGPoint(x: w*0.60, y: h*0.48))
            bolt.addLine(to: CGPoint(x: w*0.52, y: h*0.48))
            bolt.closeSubpath()
            ctx.fill(bolt, with: .color(MarketTheme.nightDeep.opacity(0.6)))
        case .plushie:
            // head
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.30, y: h*0.30, width: w*0.40, height: h*0.40)), with: .color(color))
            // ears
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.26, y: h*0.22, width: w*0.16, height: h*0.16)), with: .color(color))
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.58, y: h*0.22, width: w*0.16, height: h*0.16)), with: .color(color))
            // eyes
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.40, y: h*0.44, width: w*0.06, height: h*0.06)), with: .color(MarketTheme.nightDeep))
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.54, y: h*0.44, width: w*0.06, height: h*0.06)), with: .color(MarketTheme.nightDeep))
            // belly
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.40, y: h*0.62, width: w*0.20, height: h*0.18)), with: .color(MarketTheme.textHi.opacity(0.5)))
        }
    }
}

struct ProductGlyphView: View {
    let glyph: ProductGlyph
    var size: CGFloat = 30
    var color: Color
    var body: some View {
        Canvas { ctx, sz in
            var c = ctx
            glyph.draw(in: &c, size: sz, color: color)
        }
        .frame(width: size, height: size)
    }
}

// Security camera icon for the camera upgrade.
struct CameraIcon: View {
    var size: CGFloat = 24
    var color: Color = MarketTheme.neonCyan
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            // body
            ctx.fill(Path(roundedRect: CGRect(x: w*0.18, y: h*0.34, width: w*0.46, height: h*0.24), cornerRadius: w*0.05), with: .color(color))
            // lens
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.56, y: h*0.36, width: w*0.20, height: h*0.20)), with: .color(color.opacity(0.7)))
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.62, y: h*0.42, width: w*0.08, height: h*0.08)), with: .color(MarketTheme.nightDeep))
            // mount
            var mount = Path()
            mount.move(to: CGPoint(x: w*0.30, y: h*0.58))
            mount.addLine(to: CGPoint(x: w*0.30, y: h*0.78))
            mount.move(to: CGPoint(x: w*0.18, y: h*0.78))
            mount.addLine(to: CGPoint(x: w*0.42, y: h*0.78))
            ctx.stroke(mount, with: .color(color.opacity(0.7)), style: StrokeStyle(lineWidth: max(1, w*0.05), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

// Loyalty card icon (a little card with a heart).
struct LoyaltyIcon: View {
    var size: CGFloat = 24
    var color: Color = MarketTheme.neonPink
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            ctx.fill(Path(roundedRect: CGRect(x: w*0.16, y: h*0.28, width: w*0.68, height: h*0.44), cornerRadius: w*0.06), with: .color(color.opacity(0.85)))
            ctx.fill(Path(CGRect(x: w*0.16, y: h*0.38, width: w*0.68, height: h*0.06)), with: .color(MarketTheme.nightDeep.opacity(0.5)))
            // small heart
            var p = Path()
            let cx = w*0.5
            p.move(to: CGPoint(x: cx, y: h*0.66))
            p.addArc(center: CGPoint(x: cx - w*0.06, y: h*0.56), radius: w*0.06, startAngle: .degrees(40), endAngle: .degrees(220), clockwise: true)
            p.addArc(center: CGPoint(x: cx + w*0.06, y: h*0.56), radius: w*0.06, startAngle: .degrees(-40), endAngle: .degrees(140), clockwise: true)
            p.closeSubpath()
            ctx.fill(p, with: .color(MarketTheme.nightDeep.opacity(0.55)))
        }
        .frame(width: size, height: size)
    }
}

// Marquee sign icon (a sign with little light bulbs).
struct MarqueeIcon: View {
    var size: CGFloat = 24
    var color: Color = MarketTheme.neonAmber
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            ctx.fill(Path(roundedRect: CGRect(x: w*0.16, y: h*0.30, width: w*0.68, height: h*0.34), cornerRadius: w*0.05), with: .color(color.opacity(0.85)))
            // bulbs around top
            for i in 0..<5 {
                let x = w*0.22 + CGFloat(i)*w*0.14
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: h*0.20, width: w*0.06, height: w*0.06)), with: .color(color))
            }
            // post
            ctx.fill(Path(CGRect(x: w*0.47, y: h*0.64, width: w*0.06, height: h*0.16)), with: .color(color.opacity(0.7)))
        }
        .frame(width: size, height: size)
    }
}

// Star badge used for reputation.
struct BadgeStar: View {
    var size: CGFloat = 18
    var color: Color = MarketTheme.neonAmber
    var body: some View {
        Canvas { ctx, sz in
            let cx = sz.width*0.5, cy = sz.height*0.52, outer = sz.width*0.44, inner = sz.width*0.18
            var p = Path()
            for i in 0..<10 {
                let a = -CGFloat.pi/2 + CGFloat(i)*CGFloat.pi/5
                let r = i % 2 == 0 ? outer : inner
                let pt = CGPoint(x: cx + cos(a)*r, y: cy + sin(a)*r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

// A friendly portrait for a named regular — a person silhouette tinted to their accent,
// inside a soft ring. Distinct enough to read as "someone you know".
struct RegularPortraitIcon: View {
    var size: CGFloat = 30
    var color: Color = MarketTheme.neonPink
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            ctx.fill(Path(ellipseIn: CGRect(x: w*0.06, y: h*0.06, width: w*0.88, height: h*0.88)), with: .color(color.opacity(0.18)))
            ctx.stroke(Path(ellipseIn: CGRect(x: w*0.06, y: h*0.06, width: w*0.88, height: h*0.88)), with: .color(color.opacity(0.8)), lineWidth: max(1, w*0.05))
            let head = Path(ellipseIn: CGRect(x: w*0.36, y: h*0.22, width: w*0.28, height: w*0.28))
            ctx.fill(head, with: .color(color))
            var body = Path()
            body.move(to: CGPoint(x: w*0.5, y: h*0.52))
            body.addArc(center: CGPoint(x: w*0.5, y: h*0.94), radius: w*0.26, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            ctx.fill(body, with: .color(color.opacity(0.92)))
        }
        .frame(width: size, height: size)
    }
}
