//
//  HomeContentView.swift
//  reteach
//
//  Created by Antariksh Verma on 17/07/25.
//

import SwiftUI

struct Note: Identifiable, Equatable, Hashable {
    let id = UUID()
    var title: String
}

struct HomeContentView: View {    
    @State private var showNewNotePopup = false
    @State private var name = ""
    @StateObject private var viewModel = FilesViewModel()
    
    @State private var focusedNote: Note? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Your Notes")
                .font(
                Font.custom("InstrumentSerif-Regular", size: 40, relativeTo: .title)
                )
                .padding()
            
            ScrollView {
                NotesGallery(focusedNote: $focusedNote, notes: $viewModel.files)
            }
            .contentShape(Rectangle()) // Makes entire area tappable
            .onTapGesture {
                focusedNote = nil
            }

            Button {
                showNewNotePopup = true
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .padding()
                    .frame(width: 60, height: 60)
                    .background(Color.yellow)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
                .alert("New Note", isPresented: $showNewNotePopup) {
                    TextField("Enter name", text: $name) {}
                    Button("Done") {
                        // Creates a new note and saves it on file
                        createNotesDirectoryIfDoesntExist()
                        createNewFile(fileName: name)
                        viewModel.files.append(Note(title: name))
                        
                        // Reset name
                        name = ""
                    }
                    Button("Cancel") {}
                } message: {
                    Text("Name your note")
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// Notes Gallery View
struct NotesGallery: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @Binding var focusedNote: Note?
    @Binding var notes: [Note]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach (Array(notes.enumerated()), id: \.element) { i, note in
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        SingleNote(note: $notes[i], focusedNote: $focusedNote)
                    }
                    .padding(.horizontal, 8)
                    .simultaneousGesture(
                        LongPressGesture().onEnded { _ in
                            focusedNote = note
                        }
                    )
                    
                    // Show delete button if this is the focused note
                    if focusedNote == note {
                        Button(action: {
                            withAnimation {
                                deleteFile(fileName: note.title)
                                notes.removeAll { $0 == note }
                                focusedNote = nil
                            }
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.red)
                                .shadow(radius: 4)
                        }
                        .offset(x: -12, y: 4)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: focusedNote == notes[i])
            }
        }
        .padding()
    }
}

// Single Note View
struct SingleNote: View {
    @Binding var note: Note
    @Binding var focusedNote: Note?
    
    var body: some View {
        if focusedNote == note {
            // Disabled NavigationLink when focused
            NoteCard(note: $note, focusedNote: $focusedNote)
                .onTapGesture {
                    focusedNote = nil // unfocus on tap
                }
        } else {
            // NavigationLink only active if not focused
            NavigationLink(destination: NotesContentView(noteTitle: $note.title)) {
                NoteCard(note: $note, focusedNote: $focusedNote)
            }
        }
        NoteTitle(title: $note.title)
    }
}

// Note Card View
struct NoteCard: View {
    @Binding var note: Note
    @Binding var focusedNote: Note?
    
    var body: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 110, height: 160)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: focusedNote == note ? 10 : 4, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedNote == note ? Color.yellow : Color.clear, lineWidth: 3)
            )
    }
}

// Note Title View
struct NoteTitle: View {
    @Binding var title: String
    
    var body: some View {
        Text(title)
            .font(
                Font.custom("InstrumentSerif-Regular", size: 16, relativeTo: .caption)
            )
            .foregroundColor(.primary)
    }
}

// Model to fetch and store list of note files in directory
class FilesViewModel: ObservableObject {
    @Published var files: [Note] = []
    
    private let fileManager = FileManager.default
    private let documentsURL: URL
    private let dirUrl: URL
    
    init() {
        // Get the URL for the Documents directory
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        dirUrl = documentsURL.appendingPathComponent("reteach-notes")
        loadFiles()
    }
    
    func loadFiles() {
        do {
            // Get the list of files in the Documents directory
            let fileURLs = try fileManager.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil)
            // Extract the file names
            print(fileURLs)
            files = fileURLs.map { Note(title: $0.deletingPathExtension().lastPathComponent) }
        } catch {
            print("Error loading files: \(error.localizedDescription)")
        }
    }
}

#Preview {
    HomeContentView()
}
