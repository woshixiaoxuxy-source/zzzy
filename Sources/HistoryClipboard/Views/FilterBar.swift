import SwiftUI

/// 顶部筛选栏：搜索框 + 类型筛选
struct FilterBar: View {
    @Binding var searchText: String
    @Binding var selectedType: ContentType?
    @Binding var showStarredOnly: Bool

    var body: some View {
        VStack(spacing: 6) {
            // 搜索框
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(white: 0.35))
                    .font(.system(size: 15))

                TextField("搜索剪贴板历史…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondaryGray)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(white: 0.90))
            .cornerRadius(8)

            // 类型筛选按钮组
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    FilterChip(label: "全部", isSelected: selectedType == nil && !showStarredOnly) {
                        selectedType = nil
                        showStarredOnly = false
                    }

                    ForEach(ContentType.allCases, id: \.self) { type in
                        FilterChip(
                            icon: type.iconName,
                            label: type.displayName,
                            isSelected: selectedType == type
                        ) {
                            if selectedType == type {
                                selectedType = nil
                            } else {
                                selectedType = type
                                showStarredOnly = false
                            }
                        }
                    }

                    FilterChip(
                        icon: "star.fill",
                        label: "星标",
                        isSelected: showStarredOnly,
                        color: .yellow
                    ) {
                        showStarredOnly.toggle()
                        if showStarredOnly { selectedType = nil }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

/// 筛选小标签
struct FilterChip: View {
    let icon: String?
    let label: String
    let isSelected: Bool
    var color: Color = .accentBlue
    let action: () -> Void

    init(icon: String? = nil, label: String, isSelected: Bool, color: Color = .accentBlue, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? color.opacity(0.25) : Color(white: 0.88))
            .foregroundColor(isSelected ? color : Color(white: 0.3))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
