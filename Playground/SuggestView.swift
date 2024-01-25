//
//  SuggestView.swift
//  playground
//
//  Created by musa.yazuju on 2023/12/26.
//

import SwiftUI

struct SuggestView: View {
    let histories = ["大堀恵", "おおやようこ", "黄身子&おおえさき（イラストレーター）","リナ・オオクマ【Rina Ohkuma】"]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(histories, id: \.self) { history in
                Button(action: {
                    print("tapped \(history)")
                }, label: {
                    HStack(spacing: 0) {
                        Text(history)
                            .foregroundStyle(Color.black.opacity(0.87))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 18)
                        Spacer()
                    }
                })
                RoundedRectangle(cornerRadius: 1)
                    .foregroundStyle(Color.black.opacity(0.07))
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    SuggestView()
}
