//
//  AllProjectsView.swift
//  videoeditor
//
//  Created by Anthony Ho on 08/07/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AllProjectsView: View {
    @Query(sort: \PDFProject.modifiedDate, order: .reverse) private var allProjects: [PDFProject]
    @Binding var currentProject: PDFProject?
    @Binding var selectedImages: [UIImage]
    @State private var projectToDelete: PDFProject?
    @State private var showDeleteAlert = false
    @State private var isListView = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toggle between list and card view
                HStack {
                    Spacer()
                    Picker("View Mode", selection: $isListView) {
                        Text("Cards").tag(false)
                        Text("List").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                    .padding(.trailing, 20)
                }
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                
                if isListView {
                    listView
                } else {
                    cardView
                }
            }
            .navigationTitle("All Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
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
    }
    
    private var listView: some View {
        List {
            ForEach(allProjects, id: \.id) { project in
                ProjectListRow(project: project) {
                    loadProject(project)
                    dismiss()
                }
            }
            .onDelete(perform: deleteProjects)
        }
        .listStyle(.insetGrouped)
    }
    
    private var cardView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(allProjects, id: \.id) { project in
                    ProjectCard(project: project) {
                        loadProject(project)
                        dismiss()
                    }
                    .contextMenu {
                        Button(action: {
                            loadProject(project)
                            dismiss()
                        }) {
                            Label("Edit", systemImage: "pencil")
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
            .padding(.top, 10)
        }
    }
    
    private func loadProject(_ project: PDFProject) {
        currentProject = project
        selectedImages = project.images
    }
    
    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = allProjects[index]
            deleteProject(project)
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

struct ProjectListRow: View {
    let project: PDFProject
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 70, height: 70)
                    
                    if let firstImage = project.images.first {
                        Image(uiImage: firstImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(.gray)
                    }
                    
                    // Image count badge
                    if !project.imageDataArray.isEmpty {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(project.imageDataArray.count)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                                    .padding(4)
                            }
                            Spacer()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Project info
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        Text(relativeTimeString(from: project.modifiedDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Layout indicator
                        HStack(spacing: 4) {
                            Image(systemName: layoutIcon(for: project.photosPerPage, isLandscape: project.isLandscape))
                                .font(.system(size: 12))
                            Text("\(project.photosPerPage)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
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
