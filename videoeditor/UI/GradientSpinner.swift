import SwiftUI

struct GradientSpinner: View {
    @State private var isAnimating = false

    var body: some View {
        let angularGradient = AngularGradient(
            gradient: Gradient(colors: [.white.opacity(0.1), .white.opacity(0.5), .white]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )

        return Circle()
            .stroke(
                angularGradient,
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            .frame(width: 56, height: 56)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(Animation.linear(duration: 0.7).repeatForever(autoreverses: false)) {
                    self.isAnimating = true
                }
            }
    }
}

struct GradientSpinner_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            GradientSpinner()
        }
    }
}
