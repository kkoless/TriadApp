//
//  ProfileManager.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 31.12.2022.
//

import Combine

final class ProfileManager: ObservableObject {
    @Published private(set) var profile: Profile? = nil
    
    static let shared = ProfileManager()
    
    private var cancellable: Set<AnyCancellable> = .init()
    
    // Network manager
    
    private init() {
        print("\(self) INIT")
    }
    
    deinit {
        cancellable.forEach { $0.cancel() }
        cancellable.removeAll()
        
        print("\(self) DEINIT")
    }
}

extension ProfileManager {
    func setProfile(_ newProfile: Profile) {
        profile = newProfile
    }
    
    func logOut() {
        CredentialsManager.shared.isGuest = true
        CredentialsManager.shared.token = nil
        self.profile = nil
    }
}
