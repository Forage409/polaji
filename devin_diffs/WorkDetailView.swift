
+1
−1
import SwiftUI
 
struct WorkDetailView: View {
    let work: Work
    @StateObject private var store = WorksStore()
    @ObservedObject private var store = WorksStore.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""