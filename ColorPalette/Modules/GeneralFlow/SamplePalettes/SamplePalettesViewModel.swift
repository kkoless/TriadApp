//
//  SamplePalettesViewModel.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 01.01.2023.
//

import Foundation
import Combine

final class SamplePalettesViewModel: ObservableObject {
  typealias Routable = PopToRootRoutable & InfoRoutable
  
  let input: Input
  @Published var output: Output
  
  private weak var router: Routable?
  private var cancellable: Set<AnyCancellable> = .init()
  
  init(router: Routable? = nil) {
    self.router = router
    self.input = Input()
    self.output = Output()
    
    bindActions()
    bindTaps()
    
    print("\(self) INIT")
  }
  
  deinit {
    print("\(self) DEINIT")
    
    cancellable.forEach { $0.cancel() }
    cancellable.removeAll()
  }
}

private extension SamplePalettesViewModel {
  private func bindActions() {
    input.onAppear
      .sink { [unowned self] _ in
        output.palettes = Array(PopularPalettesManager.shared.palettes.shuffled()
          .prefix(checkLimit()))
      }
      .store(in: &cancellable)
  }
  
  private func bindTaps() {
    input.backTap
      .sink { [unowned self] _ in
        router?.popToRoot()
      }
      .store(in: &cancellable)
    
    input.paletteTap
      .sink { [unowned self] palette in
        router?.navigateToColorPalette(palette: palette)
      }
      .store(in: &cancellable)
  }
}

private extension SamplePalettesViewModel {
  private func checkLimit() -> Int {
    let firstCondition = CredentialsManager.shared.isGuest
    let secondCondition = ProfileManager.shared.profile.role.boolValue
    return firstCondition || !secondCondition ? 20 : 100
  }
}

extension SamplePalettesViewModel {
  struct Input {
    let onAppear: PassthroughSubject<Void, Never> = .init()
    let paletteTap: PassthroughSubject<ColorPalette, Never> = .init()
    let backTap: PassthroughSubject<Void, Never> = .init()
  }
  
  struct Output {
    var palettes: [ColorPalette] = .init()
  }
}
