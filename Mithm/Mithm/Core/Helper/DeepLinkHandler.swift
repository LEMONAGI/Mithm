//
//  DeepLinkHandler.swift
//  Mithm
//
//  Created by YunhakLee on 11/19/25.
//

import Foundation

final class DeepLinkHandler {
    private init() { }
    static let shared = DeepLinkHandler()
    
    func handle(_ url: URL) {
        guard url.scheme == "mithm" else { return }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = components?.queryItems
        
        let type = query?.first(where: { $0.name == "type" })?.value
        let start = query?.first(where: { $0.name == "start" })?.value
        
        print("딥링크로 앱 오픈됨:")
        print("type =", type ?? "nil")
        print("start =", start ?? "nil")
        
        // 여기서:
        //   - 해당 날짜로 달력 이동
        //   - 상세 화면 열기
        //   - "이번 주기 상세 보기" 등 네가 원하는 UX로 연결하면 됨
    }
}
