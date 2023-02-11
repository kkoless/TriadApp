//
//  ProfileCoordinator.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 30.11.2022.
//

import UIKit
import SwiftUI

protocol ProfileRoutable: AnyObject {
    func navigateToProfileScreen()
    func navigateToAuthorizationFlow()
    
    func navigateToSettingsScreen()
}

final class ProfileCoordinator: Coordinatable {
    var childCoordinators = [Coordinatable]()
    let navigationController: UINavigationController
    let type: CoordinatorType = .profile
    
    weak var finishDelegate: CoordinatorFinishDelegate?
    
    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        print("\(self) INIT")
    }
    
    func start() {
        navigateToProfileScreen()
    }
    
#if DEBUG
    deinit {
        print("\(self) DEINIT")
    }
#endif
}

extension ProfileCoordinator: ProfileRoutable {
    func navigateToProfileScreen() {
        let viewModel = ProfileViewModel(router: self)
        let profileView = ProfileView(viewModel: viewModel)
            .environmentObject(LocalizationService.shared)
        let vc = UIHostingController(rootView: profileView)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func navigateToAuthorizationFlow() {
        let authCoordinator = AuthorizationCoordinator(navigationController)
        authCoordinator.finishDelegate = self
        childCoordinators.append(authCoordinator)
        authCoordinator.start()
    }
    
    func navigateToSettingsScreen() {
        let view = SettingsView()
            .environmentObject(LocalizationService.shared)
        let vc = UIHostingController(rootView: view)
        navigationController.pushViewController(vc, animated: true)
    }
}

extension ProfileCoordinator: CoordinatorFinishDelegate {
    func coordinatorDidFinish(childCoordinator: Coordinatable, next: CoordinatorType?) {
        childCoordinators = childCoordinators.filter({ $0.type != childCoordinator.type })
        
        switch childCoordinator.type {
            case .login:
                navigationController.viewControllers.removeAll()
                if next == .tabBar { navigateToProfileScreen() }
            default: return
        }
    }
}
