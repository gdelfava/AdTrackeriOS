import SwiftUI

struct HorizontalDatePickerView: View {
    @Binding var selectedDay: StreakDayData?
    let streakData: [StreakDayData]
    
    private var sortedData: [StreakDayData] {
        streakData.sorted { $0.date < $1.date }
    }
    
    private var lastDayId: UUID? {
        sortedData.last?.id
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 8) {
                    ForEach(sortedData) { day in
                        DateCell(day: day, isSelected: day.id == selectedDay?.id)
                            .id(day.id)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDay = day
                                }
                            }
                    }
                }
                .padding(.horizontal, 4)
                .onAppear {
                    if let lastId = lastDayId {
                        proxy.scrollTo(lastId, anchor: .trailing)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Date Cell
private struct DateCell: View {
    let day: StreakDayData
    let isSelected: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day.date)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: day.date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dayName)
                .soraCaption()
                .foregroundColor(isSelected ? .white : .secondary)
            
            Text(dayNumber)
                .soraTitle3()
                .foregroundColor(isSelected ? .white : .primary)
            
            Circle()
                .fill(isToday ? Color.accentColor : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(width: 44, height: 80)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
    }
} 
