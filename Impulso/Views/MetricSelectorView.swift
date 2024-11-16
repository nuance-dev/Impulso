import SwiftUI

struct MetricSelectorView: View {
    let metric: TaskMetrics.MetricValue
    let onChange: (TaskMetrics.MetricValue) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(TaskMetrics.MetricValue.allCases, id: \.self) { value in
                Button(action: { onChange(value) }) {
                    HStack {
                        Text(value.description)
                        if metric == value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(metric == value ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(4)
            }
        }
        .frame(width: 120)
    }
}
