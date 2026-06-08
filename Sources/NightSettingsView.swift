import SwiftUI

struct NightSettingsView: View {
    @ObservedObject var store: MarketStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var showPrivacy = false

    var body: some View {
        ZStack {
            MarketTheme.night.ignoresSafeArea()
            VStack(spacing: 0) {
                // Custom header with close
                HStack {
                    Text("Settings")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(MarketTheme.textHi)
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        ZStack {
                            Circle().fill(MarketTheme.panel).frame(width: 34, height: 34)
                            CloseIcon(size: 16, color: MarketTheme.textMid)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // About card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                StoreMarkIcon(size: 40, color: MarketTheme.neonAmber)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Midnight Mini")
                                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                                        .foregroundColor(MarketTheme.textHi)
                                    Text("Run the late-night counter.")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(MarketTheme.textMid)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .marketCard()

                        // Privacy policy row → opens WebPanel directly (no redirect check)
                        Button(action: { showPrivacy = true }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10).fill(MarketTheme.nightDeep).frame(width: 40, height: 40)
                                    ShieldIcon(size: 22, color: MarketTheme.neonCyan)
                                }
                                Text("Privacy Policy")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(MarketTheme.textHi)
                                Spacer()
                                ChevronIcon(size: 16, color: MarketTheme.textLow)
                            }
                            .padding(14)
                            .marketCard()
                        }
                        .buttonStyle(.plain)

                        // Helpful blurb
                        Text("Progress saves automatically on this device.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(MarketTheme.textLow)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.top, 4)

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPrivacy) {
            NightMarketWebPanel(urlString: "https://midnightmini.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
        }
    }
}

// Shield icon for privacy.
struct ShieldIcon: View {
    var size: CGFloat = 22
    var color: Color = MarketTheme.neonCyan
    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            var p = Path()
            p.move(to: CGPoint(x: w*0.5, y: h*0.12))
            p.addLine(to: CGPoint(x: w*0.84, y: h*0.26))
            p.addLine(to: CGPoint(x: w*0.84, y: h*0.54))
            p.addCurve(to: CGPoint(x: w*0.5, y: h*0.90),
                       control1: CGPoint(x: w*0.84, y: h*0.74),
                       control2: CGPoint(x: w*0.68, y: h*0.84))
            p.addCurve(to: CGPoint(x: w*0.16, y: h*0.54),
                       control1: CGPoint(x: w*0.32, y: h*0.84),
                       control2: CGPoint(x: w*0.16, y: h*0.74))
            p.addLine(to: CGPoint(x: w*0.16, y: h*0.26))
            p.closeSubpath()
            ctx.stroke(p, with: .color(color), lineWidth: max(1.5, w*0.07))
            var check = Path()
            check.move(to: CGPoint(x: w*0.36, y: h*0.50))
            check.addLine(to: CGPoint(x: w*0.47, y: h*0.62))
            check.addLine(to: CGPoint(x: w*0.66, y: h*0.38))
            ctx.stroke(check, with: .color(color), style: StrokeStyle(lineWidth: max(1.5, w*0.08), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// Chevron / disclosure arrow.
struct ChevronIcon: View {
    var size: CGFloat = 16
    var color: Color = MarketTheme.textLow
    var body: some View {
        Canvas { ctx, sz in
            var p = Path()
            p.move(to: CGPoint(x: sz.width*0.38, y: sz.height*0.24))
            p.addLine(to: CGPoint(x: sz.width*0.64, y: sz.height*0.5))
            p.addLine(to: CGPoint(x: sz.width*0.38, y: sz.height*0.76))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: max(1.5, sz.width*0.10), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}
