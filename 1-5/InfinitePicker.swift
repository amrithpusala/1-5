import SwiftUI

struct InfinitePicker: View {
    let title: String
    let range: ClosedRange<Int>
    @Binding var value: Int

    private var base: [Int] { Array(range) }
    private var items: [Int] { Array(repeating: base, count: 40).flatMap { $0 } }

    @State private var index: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.75))

            Picker("", selection: $index) {
                ForEach(items.indices, id: \.self) { i in
                    Text("\(items[i])")
                        .foregroundColor(.white)
                        .font(.title2)
                        .tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 110, height: 130)
            .clipped()
            .onChange(of: index) { i in
                value = items[i]
            }
            .onAppear {
                if let first = items.firstIndex(of: value) {
                    index = first + (items.count / 2 - base.count / 2)
                } else {
                    value = range.lowerBound
                    index = items.count / 2
                }
            }
        }
    }
}
