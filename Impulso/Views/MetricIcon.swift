import SwiftUI

struct MetricIcon: View {
    let type: MetricType
    
    var body: some View {
        Image(systemName: type.iconName)
            .foregroundColor(type.color)
            .frame(width: 24, height: 24)
    }
}
