import SwiftUI
import SwiftData
import PhotosUI

struct HomeView: View {
    @Query(sort: \PDFProject.modifiedDate, order: .reverse) private var recentProjects: [PDFProject]
    @Binding var selectedPickerItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    @Binding var currentProject: PDFProject?
    @State private var projectToDelete: PDFProject?
    @State private var showDeleteAlert = false
    @State private var showAllProjects = false
    @State private var projectToRename: PDFProject?
    @State private var newProjectName = ""
    @State private var showRenameAlert = false
    @EnvironmentObject var iapManager: IAPManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    private let freeLimit = 3
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                // New Project Section - Takes full screen when no projects
                PhotoSelectorView(
                    selectedPickerItems: $selectedPickerItems,
                    selectedImages: $selectedImages,
                    currentProject: $currentProject
                )

                .frame(height: recentProjects.isEmpty ? UIScreen.main.bounds.height - 100 : 300)
                .padding(.top, recentProjects.isEmpty ? 0 : 50)
                
                // Recent Projects Section
                if !recentProjects.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Recent Projects")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            Spacer()
                            if recentProjects.count > 4 {
                                Button(action: {
                                    showAllProjects = true
                                }) {
                                    Text("See All")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(Color(UIColor.systemGray6))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color(UIColor.systemGray5), lineWidth: 1)
                                        )
                                }
                            }
                          
                        }
                          .padding(.horizontal, 20)
                        .padding(.top, 30)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(recentProjects.prefix(4), id: \.id) { project in
                                ProjectCard(project: project) {
                                    loadProject(project)
                                }
                                .contextMenu {
                                    Button(action: {
                                        projectToRename = project
                                        newProjectName = project.title
                                        showRenameAlert = true
                                    }) {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        projectToDelete = project
                                        showDeleteAlert = true
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Bottom spacing
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
        }
       
        .alert("Delete Project?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let project = projectToDelete {
                    deleteProject(project)
                    projectToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
        } message: {
            if let project = projectToDelete {
                Text("Are you sure you want to delete \"\(project.title)\"? This action cannot be undone.")
            }
        }
        .fullScreenCover(isPresented: $showAllProjects) {
            AllProjectsView(currentProject: $currentProject, selectedImages: $selectedImages)
        }
        .alert("Rename Project", isPresented: $showRenameAlert) {
            TextField("Enter new name", text: $newProjectName)
                .autocorrectionDisabled()
            
            Button("Save") {
                if let project = projectToRename {
                    renameProject(project, to: newProjectName)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let project = projectToRename {
                Text("Enter a new name for \"\(project.title)\".")
            }
        }
    }
    
    private func loadProject(_ project: PDFProject) {
        currentProject = project
        selectedImages = project.images
        // The ContentView will automatically switch to editor mode when selectedImages is populated
    }
    
    private func renameProject(_ project: PDFProject, to newName: String) {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        project.title = newName
        project.modifiedDate = Date()
        do {
            try modelContext.save()
        } catch {
            print("Failed to save renamed project: \(error)")
        }
    }
    
    private func deleteProject(_ project: PDFProject) {
        // If deleting the currently active project, clear it
        if currentProject?.id == project.id {
            currentProject = nil
            selectedImages = []
        }
        
        // Delete from SwiftData
        modelContext.delete(project)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete project: \(error)")
        }
    }
}


struct ProjectCard: View {
    let project: PDFProject
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                GeometryReader { geometry in
                    ZStack {
                        if let firstImage = project.images.first {
                            Image(uiImage: firstImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("No Images")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        ImageCountBadge(count: project.imageDataArray.count)
                    )
                }
                .aspectRatio(1, contentMode: .fit)

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .frame(minHeight: 40, alignment: .top)

                    HStack {
                        Text(relativeTimeString(from: project.modifiedDate))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 2) {
                            Image(systemName: layoutIcon(for: project.photosPerPage, isLandscape: project.isLandscape))
                                .font(.system(size: 10))
                            Text("\(project.photosPerPage)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func layoutIcon(for photosPerPage: Int, isLandscape: Bool) -> String {
        switch photosPerPage {
        case 1:
            return isLandscape ? "rectangle" : "rectangle.portrait"
        case 2:
            return isLandscape ? "rectangle.split.2x1" : "rectangle.split.1x2"
        case 4:
            return "rectangle.split.2x2"
        default:
            return isLandscape ? "rectangle" : "rectangle.portrait"
        }
    }
}

// A helper view for the count badge, to keep the main body clean.
struct ImageCountBadge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            VStack {
                HStack {
                    Spacer()
                    Text("\(count)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding(8)
                }
                Spacer()
            }
        }
    }
}
