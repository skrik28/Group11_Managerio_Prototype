import SwiftUI

// Models
struct Project: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date
    var location: String
    var budget: Double
    var isCompleted: Bool = false
}

class ProjectStore: ObservableObject {
    @Published var projects: [Project] = [] {
        didSet {
            save()
        }
    }
    
    init() {
        load()
        
        // Added mock data for ui demo
        if projects.isEmpty {
            projects = [
                Project(title: "Website Redesign", description: "Redesign company website", startDate: Date(), endDate: Date().addingTimeInterval(60*60*24*30), location: "Remote", budget: 5000),
                Project(title: "Mobile App Development", description: "Create iOS app for client", startDate: Date(), endDate: Date().addingTimeInterval(60*60*24*60), location: "Office", budget: 15000)
            ]
        }
    }
    
    func addProject(_ project: Project) {
        projects.append(project)
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "Projects")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "Projects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }
    
    var totalProjects: Int {
        return projects.count
    }
    
    var totalBudget: Double {
        return projects.reduce(0) { $0 + $1.budget }
    }
    
    var completedProjects: Int {
        return projects.filter { $0.isCompleted }.count
    }
}

// Views
struct HomeView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("Managerio")
                .font(.custom("Noteworthy-Bold", size: 37))
                .foregroundColor(.blue)
            
            Text("Project Management System\nFor iPhone 16 Pro")
                .font(.title2)
                .padding(.bottom, 50)
            
            VStack(spacing: 15) {
                Text("Developed by:")
                    .font(.headline)
                
                Text("Simon Kriksciunas")
                    .font(.title3)
                
                Text("Tomer Edelman")
                    .font(.title3)
                
                Text("Pablo Arango Gomez")
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            
            Spacer()
        }
        .padding()
    }
}

struct DashboardView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var selectedDate = Date()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Dashboard")
                    .font(.custom("Noteworthy-Bold", size: 45))
                    .padding(.top, -20)
                    .padding(.leading, 15)

                // Stats cards
                HStack(spacing: 20) {
                    StatCard(title: "Total Projects", value: "\(projectStore.totalProjects)", icon: "folder", color: .blue)
                    StatCard(title: "Completed", value: "\(projectStore.completedProjects)", icon: "checkmark.circle", color: .green)
                }
                
                HStack(spacing: 20) {
                    StatCard(title: "In Progress", value: "\(projectStore.totalProjects - projectStore.completedProjects)", icon: "clock", color: .orange)
                    StatCard(title: "Total Budget", value: "$\(Int(projectStore.totalBudget))", icon: "dollarsign.circle", color: .purple)
                }.padding(.bottom)
                
                // Calendar
                CalendarView(selectedDate: $selectedDate)
                    .frame(height: 300)
                    .padding(.top)
                    .padding(.bottom)
                
                // Projects for selected date
                Text("Projects on \(formattedDate(selectedDate))")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(projectsOnSelectedDate()) { project in
                    ProjectRow(project: project)
                }
                
                if projectsOnSelectedDate().isEmpty {
                    Text("No projects scheduled for this date")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                }
            }
            .padding()
        }
        .padding(.top, 10)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func projectsOnSelectedDate() -> [Project] {
        let calendar = Calendar.current
        return projectStore.projects.filter { project in
            calendar.isDate(selectedDate, inSameDayAs: project.startDate) ||
            calendar.isDate(selectedDate, inSameDayAs: project.endDate) ||
            (selectedDate > project.startDate && selectedDate < project.endDate)
        }
    }
}

struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct CalendarView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    @State private var displayMonth: Date = Date()
    
    var body: some View {
        VStack {
            // Month selector
            HStack {
                Button(action: { previousMonth() }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthYearString(from: displayMonth))
                    .font(.headline)
                
                Spacer()
                
                Button(action: { nextMonth() }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.bottom, 10)
            
            // Days of week header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
                            .onTapGesture {
                                selectedDate = date
                            }
                    } else {
                        // Empty cell for days not in current month
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var daysOfWeek: [String] {
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        var days = [Date?]()
        
        let range = calendar.range(of: .day, in: .month, for: displayMonth)!
        let numDays = range.count
        
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // Add empty cells for days before the first of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in 1...numDays {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!
            days.append(date)
        }
        
        // Add empty cells to complete the last week if needed
        let remainingDays = (7 - (days.count % 7)) % 7
        for _ in 0..<remainingDays {
            days.append(nil)
        }
        
        return days
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) {
            displayMonth = newMonth
        }
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) {
            displayMonth = newMonth
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.blue : Color.clear)
                .frame(width: 40, height: 40)
            
            Text("\(calendar.component(.day, from: date))")
                .foregroundColor(isSelected ? .white : isToday() ? .blue : .black)
                .font(.system(size: 16, weight: isToday() ? .bold : .regular))
        }
        .frame(height: 40)
    }
    
    private func isToday() -> Bool {
        return calendar.isDateInToday(date)
    }
}

struct ProjectRow: View {
    var project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(project.title)
                .font(.headline)
            
            Text(project.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Label("$\(Int(project.budget))", systemImage: "dollarsign.circle")
                    .font(.caption)
                
                Spacer()
                
                Label(project.location, systemImage: "mappin.circle")
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct CreateProjectView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(60*60*24*7)
    @State private var location = ""
    @State private var budget = ""
    @State private var showingAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Create New Project")
                    .font(.custom("Noteworthy-Bold", size: 37))
                    .padding(.top, -20)
                    .padding(.leading, 15)
                    .padding(.bottom, 5)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Title")
                        .font(.headline)
                    
                    TextField("Enter project title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Date")
                        .font(.headline)
                    
                    DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("End Date")
                        .font(.headline)
                    
                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                    
                    TextField("Enter project location", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget ($)")
                        .font(.headline)
                    
                    TextField("Enter project budget", text: $budget)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                
                Button(action: createProject) {
                    Text("Create Project")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top)
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("Project Created"),
                        message: Text("Your new project has been added successfully."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .padding()
        }
        .padding(.top, 10)
    }
    
    func createProject() {
        guard !title.isEmpty, !description.isEmpty, !location.isEmpty, !budget.isEmpty else {
            return
        }
        
        let newProject = Project(
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location,
            budget: Double(budget) ?? 0
        )
        
        projectStore.addProject(newProject)
        
        // Reset form
        title = ""
        description = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(60*60*24*7)
        location = ""
        budget = ""
        
        showingAlert = true
    }
}

struct ProjectListView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var searchText = ""
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projectStore.projects
        } else {
            return projectStore.projects.filter { project in
                project.title.localizedCaseInsensitiveContains(searchText) ||
                project.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack {
            Text("Project List")
                .font(.custom("Noteworthy-Bold", size: 37))
                .padding(.top, -5)
                .padding(.bottom, 20)
            
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            List {
                ForEach(filteredProjects) { project in
                    ProjectListRow(project: project)
                }
                .onDelete(perform: deleteProjects)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    func deleteProjects(at offsets: IndexSet) {
        let projectsToDelete = offsets.map { filteredProjects[$0] }
        for project in projectsToDelete {
            if let index = projectStore.projects.firstIndex(where: { $0.id == project.id }) {
                projectStore.projects.remove(at: index)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search projects", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct ProjectListRow: View {
    var project: Project
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(project.title)
                        .font(.headline)
                    
                    Text(project.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("$\(Int(project.budget))")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(formattedDateRange())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetail.toggle()
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingDetail) {
            ProjectDetailView(project: project)
        }
    }
    
    func formattedDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: project.startDate)) - \(formatter.string(from: project.endDate))"
    }
}

struct ProjectDetailView: View {
    var project: Project
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(project.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Group {
                    DetailRow(icon: "doc.text", title: "Description", value: project.description)
                    
                    DetailRow(icon: "calendar", title: "Start Date", value: formattedDate(project.startDate))
                    
                    DetailRow(icon: "calendar", title: "End Date", value: formattedDate(project.endDate))
                    
                    DetailRow(icon: "mappin", title: "Location", value: project.location)
                    
                    DetailRow(icon: "dollarsign.circle", title: "Budget", value: "$\(Int(project.budget))")
                    
                    DetailRow(icon: "checkmark.circle", title: "Status", value: project.isCompleted ? "Completed" : "In Progress")
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    var icon: String
    var title: String
    var value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
            }
        }
    }
}

// Navigation
struct ContentView: View {
    @StateObject var projectStore = ProjectStore()
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Dashboard")
                }
                .tag(1)
            
            CreateProjectView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Create")
                }
                .tag(2)
            
            ProjectListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Projects")
                }
                .tag(3)
        }
        .environmentObject(projectStore)
    }
}

// App Entry Point
@main
struct ManagerioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
