//
//  Scenes.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit
/*
 1. 인증
 2. 그룹 채널
     1. 그룹 채널 목록
     2. 그룹 채널 생성
 3. 채팅 화면
     1. 이미지 업로드
     2. 메시지 삭제
 4. 설정
     1. 닉네임 변경
     2. 앱 아이디 설정
 */

enum State: StateType {
    case splash
    case auth
    case main
}

extension State {
    static func == (lhs: State, rhs: State) -> Bool {
        switch (lhs, rhs) {
        case (.splash, .splash): return true
        case (.auth, .auth): return true
        case (.main, .main): return true
        default: return false
        }
    }
    
    var sceneData: Any? {
        switch self {
        case .splash: return nil
        case .auth: return nil
        case .main: return nil
        }
    }
    
    var sceneType: StateSceneType.Type {
        switch self {
        case .splash: return SplashController.self
        case .auth: return AuthController.self
        case .main: return ChannelNavigationController.self
        }
    }
}
