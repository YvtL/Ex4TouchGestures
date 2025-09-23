import SwiftUI

// MARK: - Main App
@main
struct ColorMixerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
¢
// MARK: - Content View
struct ContentView: View {
    @State private var currentColor = Color.blue
    @State private var brushSize: CGFloat = 20
    @State private var drawnPaths: [DrawnPath] = []
    @State private var currentPath = Path()
    @State private var isDrawing = false
    @State private var showColorWheel = false
    @State private var colorWheelRotation: Double = 0
    @State private var sampledColor: Color?
    @State private var showGestureHint = true
    @State private var selectedColorIndex = 2
    
    // Preset colors for quick selection
    let presetColors: [Color] = [
        Color(red: 1.0, green: 0.3, blue: 0.3),  // Red
        Color(red: 1.0, green: 0.6, blue: 0.2),  // Orange
        Color(red: 1.0, green: 0.9, blue: 0.3),  // Yellow
        Color(red: 0.3, green: 0.9, blue: 0.3),  // Green
        Color(red: 0.3, green: 0.6, blue: 1.0),  // Blue
        Color(red: 0.6, green: 0.3, blue: 0.9),  // Purple
        Color(red: 1.0, green: 0.4, blue: 0.6),  // Pink
        Color(red: 0.2, green: 0.2, blue: 0.2),  // Black
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "FAFAFA"), Color(hex: "E8E8E8")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView(
                    brushSize: $brushSize,
                    currentColor: $currentColor,
                    onClear: clearCanvas
                )
                
                // Canvas
                ZStack {
                    // Drawing Canvas
                    Canvas { context, size in
                        // Draw all completed paths
                        for drawnPath in drawnPaths {
                            context.stroke(
                                drawnPath.path,
                                with: .color(drawnPath.color),
                                lineWidth: drawnPath.lineWidth
                            )
                        }
                        
                        // Draw current path
                        if isDrawing {
                            context.stroke(
                                currentPath,
                                with: .color(currentColor),
                                lineWidth: brushSize
                            )
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 10)
                    .gesture(drawGesture)
                    .gesture(longPressGesture)
                    .gesture(pinchGesture)
                    
                    // Gesture Hints
                    if showGestureHint {
                        GestureHintView()
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    withAnimation {
                                        showGestureHint = false
                                    }
                                }
                            }
                    }
                    
                    // Color Wheel Overlay
                    if showColorWheel {
                        ColorWheelView(
                            selectedColorIndex: $selectedColorIndex,
                            rotation: $colorWheelRotation,
                            onColorSelected: { color in
                                currentColor = color
                                withAnimation {
                                    showColorWheel = false
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
                
                // Color Palette
                ColorPaletteView(
                    presetColors: presetColors,
                    currentColor: $currentColor,
                    selectedColorIndex: $selectedColorIndex
                )
                
                // Bottom Tools
                BottomToolsView(
                    showColorWheel: $showColorWheel,
                    showGestureHint: $showGestureHint
                )
            }
        }
    }
    
    // MARK: - Gestures
    
    // Drawing Gesture
    var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDrawing {
                    currentPath = Path()
                    isDrawing = true
                }
                currentPath.addLine(to: value.location)
            }
            .onEnded { _ in
                drawnPaths.append(DrawnPath(
                    path: currentPath,
                    color: currentColor,
                    lineWidth: brushSize
                ))
                isDrawing = false
            }
    }
    
    // Long Press to Sample Color
    var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                // Sample the last drawn color
                if let lastPath = drawnPaths.last {
                    currentColor = lastPath.color
                    updateSelectedColorIndex()
                }
            }
    }
    
    // Pinch to Adjust Brush Size
    var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newSize = brushSize * value
                brushSize = min(max(newSize, 5), 100)
            }
    }
    
    // MARK: - Helper Functions
    
    func clearCanvas() {
        withAnimation(.spring()) {
            drawnPaths.removeAll()
            currentPath = Path()
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    func updateSelectedColorIndex() {
        if let index = presetColors.firstIndex(where: {
            $0.description == currentColor.description
        }) {
            selectedColorIndex = index
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var brushSize: CGFloat
    @Binding var currentColor: Color
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            // App Title
            VStack(alignment: .leading, spacing: 4) {
                Text("Color Mixer")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Text("Gesture-Based Art Studio")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "7F8C8D"))
            }
            
            Spacer()
            
            // Brush Size Indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(currentColor)
                    .frame(width: brushSize, height: brushSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3)
                
                Text("\(Int(brushSize))px")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "7F8C8D"))
            }
            
            // Clear Button
            Button(action: onClear) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "E74C3C"))
                    .clipShape(Circle())
                    .shadow(color: Color(hex: "E74C3C").opacity(0.3), radius: 5)
            }
        }
        .padding()
    }
}

// MARK: - Color Palette View
struct ColorPaletteView: View {
    let presetColors: [Color]
    @Binding var currentColor: Color
    @Binding var selectedColorIndex: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(0..<presetColors.count, id: \.self) { index in
                    ColorButton(
                        color: presetColors[index],
                        isSelected: index == selectedColorIndex,
                        action: {
                            currentColor = presetColors[index]
                            selectedColorIndex = index
                            
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 80)
    }
}

// MARK: - Color Button
struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: color.opacity(0.4), radius: isSelected ? 8 : 4)
                .scaleEffect(isSelected ? 1.2 : 1.0)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Bottom Tools View
struct BottomToolsView: View {
    @Binding var showColorWheel: Bool
    @Binding var showGestureHint: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Color Wheel Toggle
            Button(action: {
                withAnimation(.spring()) {
                    showColorWheel.toggle()
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 24))
                    Text("Color Wheel")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(showColorWheel ? .white : Color(hex: "3498DB"))
                .frame(width: 90, height: 60)
                .background(showColorWheel ? Color(hex: "3498DB") : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 5)
            }
            
            // Help Button
            Button(action: {
                withAnimation {
                    showGestureHint.toggle()
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 24))
                    Text("Gestures")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(Color(hex: "9B59B6"))
                .frame(width: 90, height: 60)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 5)
            }
        }
        .padding()
    }
}

// MARK: - Gesture Hint View
struct GestureHintView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("Gesture Controls")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                GestureRow(icon: "hand.draw.fill", text: "Drag to draw")
                GestureRow(icon: "hand.tap.fill", text: "Long press to sample color")
                GestureRow(icon: "arrow.up.left.and.arrow.down.right", text: "Pinch to resize brush")
                GestureRow(icon: "rotate.3d", text: "2-finger rotate color wheel")
                GestureRow(icon: "hand.raised.fingers.spread.fill", text: "3-finger swipe to clear")
            }
            
            Text("Tap anywhere to dismiss")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(0.3)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Gesture Row
struct GestureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Color Wheel View
struct ColorWheelView: View {
    @Binding var selectedColorIndex: Int
    @Binding var rotation: Double
    let onColorSelected: (Color) -> Void
    
    let wheelColors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .cyan, .blue, .indigo, .purple, .pink
    ]
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onColorSelected(wheelColors[selectedColorIndex])
                }
            
            // Color Wheel
            ZStack {
                ForEach(0..<wheelColors.count, id: \.self) { index in
                    WheelSegment(
                        color: wheelColors[index],
                        startAngle: Double(index) * 36,
                        isSelected: false
                    )
                    .rotationEffect(.degrees(rotation))
                    .onTapGesture {
                        onColorSelected(wheelColors[index])
                        
                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                    }
                }
                
                // Center circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.2), radius: 10)
                
                Text("Select\nColor")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .multilineTextAlignment(.center)
            }
            .frame(width: 250, height: 250)
            .rotationEffect(.degrees(rotation))
            .gesture(
                RotationGesture()
                    .onChanged { value in
                        rotation = value.degrees
                    }
            )
        }
    }
}

// MARK: - Wheel Segment
struct WheelSegment: View {
    let color: Color
    let startAngle: Double
    let isSelected: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: 125,
                    startAngle: .degrees(startAngle - 90),
                    endAngle: .degrees(startAngle + 36 - 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
            .overlay(
                Path { path in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: 125,
                        startAngle: .degrees(startAngle - 90),
                        endAngle: .degrees(startAngle + 36 - 90),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
        }
    }
}

// MARK: - Models
struct DrawnPath {
    let path: Path
    let color: Color
    let lineWidth: CGFloat
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
