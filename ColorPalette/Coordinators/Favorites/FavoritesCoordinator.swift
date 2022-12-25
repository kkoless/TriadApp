//
//  FavoritesCoordinator.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 25.12.2022.
//

import UIKit
import SwiftUI

protocol FavoritesRoutable: AnyObject {
    func pop()
    func navigateToFavoritesScreen()
    func navigateToColorPalette(palette: ColorPalette)
    
    func navigateToAddNewColor()
    func navigateToCreatePalette()
}

final class FavoritesCoordinator: Coordinatable {
    var childCoordinators = [Coordinatable]()
    let navigationController: UINavigationController
    let type: CoordinatorType = .favorites
    
    weak var finishDelegate: CoordinatorFinishDelegate?
    
    init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        print("\(self) INIT")
    }
    
    func start() {
        navigateToFavoritesScreen()
    }
    
#if DEBUG
    deinit {
        print("\(self) DEINIT")
    }
#endif
}

extension FavoritesCoordinator: FavoritesRoutable {
    func pop() {
        navigationController.popViewController(animated: true)
    }
    
    func navigateToFavoritesScreen() {
        let profileView = FavoritesView(router: self)
            .environmentObject(PaletteStorageManager.shared)
        let vc = UIHostingController(rootView: profileView)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func navigateToColorPalette(palette: ColorPalette) {
        let view = ColorPaletteView(palette: palette)
        let vc = UIHostingController(rootView: view)
        navigationController.present(vc, animated: true)
    }
    
    func navigateToAddNewColor() {
        let view = AddNewColorView().environmentObject(FavoriteManager.shared)
        let vc = UIHostingController(rootView: view)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func navigateToCreatePalette() {
        let view = CreateColorPaletteView(router: self)
            .environmentObject(PaletteStorageManager.shared)
        let vc = UIHostingController(rootView: view)
        navigationController.pushViewController(vc, animated: true)
    }
}