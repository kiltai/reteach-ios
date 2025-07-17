//
//  ContentView.swift
//  reteach
//
//  Created by Antariksh Verma on 16/07/25.
//

import SwiftUI
import PencilKit
import Combine

extension PKStroke: Equatable {
  public static func == (lhs: PKStroke, rhs: PKStroke) -> Bool {
    return (lhs as PKStrokeReference) === (rhs as PKStrokeReference)
  }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView // Binding for the canvas
    
    @Binding var drawing: PKDrawing // Binding for the drawing
    
    @Binding var selectedStrokes: [PKStroke] // Binding for the strokes selected with lasso
    
    // Create tool picker
    let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput // Allows drawing with finger or Apple Pencil
        
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        canvas.delegate = context.coordinator
        
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        
        if uiView.drawing.dataRepresentation() != drawing.dataRepresentation() {
                uiView.drawing = drawing
        }
        
        context.coordinator.lastDrawing = drawing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        var lastDrawing: PKDrawing?

        init(_ parent: CanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            parent.updateLassoSelection(from: canvasView)
        }
    }
    
    // 👇 Lasso detection trick
    func updateLassoSelection(from canvasView: PKCanvasView) {
        guard canvasView.tool is PKLassoTool else {
            selectedStrokes = []
            return
        }

        let original = canvasView.drawing.strokes

        // Temporarily delete selected strokes
        UIApplication.shared.sendAction(#selector(UIResponderStandardEditActions.delete), to: nil, from: nil, for: nil)

        let remaining = canvasView.drawing.strokes

        // Restore drawing
        canvasView.drawing.strokes = original

        // Find deleted strokes = selected
        let selected = original.filter { !remaining.contains($0) }
        selectedStrokes = selected
    }
}

struct NotesContentView: View {
    @State private var canvasView = PKCanvasView()
    
    @State private var drawing = PKDrawing()
    @State private var selectedStrokes: [PKStroke] = []
    
    @Binding public var noteTitle: String
    
    @StateObject private var viewModel = NoteViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("all notes autosaved")
                    .font(.custom("InstrumentSerif-Regular", size: 20))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    // Add any action (clear canvas, export, etc.)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.yellow)
            ZStack {
                CanvasView(canvas: $canvasView, drawing: $viewModel.drawing, selectedStrokes: $selectedStrokes)
                
                if !selectedStrokes.isEmpty {
                    Button(action: {
                        // Remove selected strokes from drawing
                        drawing = PKDrawing(strokes: drawing.strokes.filter { !selectedStrokes.contains($0) })
                        selectedStrokes = []
                    }) {
                        Image(systemName: "waveform.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.black)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding()
                    .transition(.scale)
                }
            }
            .animation(.easeInOut, value: selectedStrokes.count)
            .edgesIgnoringSafeArea(.all)
        }
    }
}

// Model for viewing drawing and autosaving
class NoteViewModel: ObservableObject {
    @Published var drawing: PKDrawing = PKDrawing()
    
    private var cancellables = Set<AnyCancellable>()
    var title: String

    init() {
        self.title = ""
        loadDrawing()
        
        $drawing
            .dropFirst() // skip initial load
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] newDrawing in
                self?.autosave(drawing: newDrawing)
            }
            .store(in: &cancellables)
    }
    
    func setTitle(noteTitle: String) {
        self.title = noteTitle
    }

    func autosave(drawing: PKDrawing) {
        let fileURL = getNotePath()
        do {
            let data = drawing.dataRepresentation()
            try data.write(to: fileURL)
            print("✅ Drawing autosaved.")
        } catch {
            print("❌ Error saving drawing: \(error)")
        }
    }

    func loadDrawing() {
        let fileURL = getNotePath()
        guard let data = try? Data(contentsOf: fileURL),
              let loadedDrawing = try? PKDrawing(data: data) else {
            return
        }
        drawing = loadedDrawing
    }

    private func getNotePath() -> URL {
        let fileUrl = getFilePath(fileName: title)
        return fileUrl
    }
}

#Preview {
    NotesContentView(noteTitle: .constant("Sample note"))
}
