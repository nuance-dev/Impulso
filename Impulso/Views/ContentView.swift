import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: ImpulsoViewModel
    @Environment(\.managedObjectContext) private var viewContext
    
    init() {
        let persistenceController = PersistenceController.shared
        let priorityCalculator = PriorityCalculator()
        _viewModel = StateObject(wrappedValue: ImpulsoViewModel(
            persistenceController: persistenceController,
            priorityCalculator: priorityCalculator
        ))
    }
    
    var body: some View {
        NavigationView {
            ImpulsoView(viewModel: viewModel)
        }
    }
}
