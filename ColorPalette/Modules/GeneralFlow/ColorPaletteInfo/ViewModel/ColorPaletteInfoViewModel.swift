//
//  ColorPaletteInfoViewModel.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 10.02.2023.
//

import Foundation
import Combine

final class ColorPaletteInfoViewModel: ObservableObject {
  typealias FavoriteService = FavoritesAddServiceProtocol & FavoritesDeleteServiceProtocol
  
  let input: Input
  @Published var output: Output
  
  private let palette: ColorPalette
  private let service: FavoriteService
  private let favoritesManager: FavoriteManager
  
  private var cancellable: Set<AnyCancellable> = .init()
  
  init(
    palette: ColorPalette,
    service: FavoriteService = FavoritesNetworkService.shared
  ) {
    self.input = Input()
    self.output = Output()
    
    self.palette = palette
    self.favoritesManager = .shared
    self.service = service
    
    bindRequests()
    
    print("\(self) INIT")
  }
  
  deinit {
    cancellable.forEach { $0.cancel() }
    cancellable.removeAll()
    
    print("\(self) DEINIT")
  }
}

private extension ColorPaletteInfoViewModel {
  private func bindRequests() {
    input.onAppear
      .map { [weak self] _ -> Bool in
        guard let self else { return false }
        return checkFavorite(palette: palette)
      }
      .sink { [weak self] isFavorite in
        self?.output.isFavorite = isFavorite
      }
      .store(in: &cancellable)
    
    input.favTap
      .filter { [weak self] _ in
        guard let output = self?.output else { return false }
        return !CredentialsManager.shared.isGuest && output.isFavorite
      }
      .flatMap { [unowned self] _ -> AnyPublisher<Void, ApiError> in
        service.deletePalette(paletteId: palette.id)
      }
      .sink { response in
        switch response {
        case let .failure(apiError):
          print("\(apiError.localizedDescription)")
        case .finished:
          print("finished")
        }
      } receiveValue: { [weak self] _ in
        guard let self else { return }
        favoritesManager.removePalette(palette)
        output.isFavorite.toggle()
      }
      .store(in: &cancellable)
    
    input.favTap
      .filter { [weak self] _ in
        guard let self else { return false }
        return !CredentialsManager.shared.isGuest && (!output.isFavorite && !favoritesManager.isPalettesLimit)
      }
      .flatMap { [unowned self] _ -> AnyPublisher<Void, ApiError> in service.addPalette(palette: palette) }
      .sink { response in
        switch response {
        case let .failure(apiError):
          print("\(apiError.localizedDescription)")
        case .finished:
          print("finished")
        }
      } receiveValue: { [weak self] _ in
        guard let self else { return }
        favoritesManager.addPalette(palette)
        output.isFavorite.toggle()
      }
      .store(in: &cancellable)
    
    input.favTap
      .filter { _ in CredentialsManager.shared.isGuest }
      .sink { [weak self] _ in
        self?.changeFavoriteState()
      }
      .store(in: &cancellable)
    
  }
  
  private func checkFavorite(palette: ColorPalette) -> Bool {
    favoritesManager
      .palettes
      .contains(where: { $0.hashValue == palette.hashValue })
  }
  
  private func changeFavoriteState() {
    if output.isFavorite {
      favoritesManager.removePalette(palette)
      output.isFavorite.toggle()
    } else {
      if !favoritesManager.isPalettesLimit {
        favoritesManager.addPalette(palette)
        output.isFavorite.toggle()
      }
    }
  }
}

extension ColorPaletteInfoViewModel {
  struct Input {
    let onAppear: PassthroughSubject<Void, Never> = .init()
    let favTap: PassthroughSubject<Void, Never> = .init()
  }
  
  struct Output {
    var isFavorite: Bool = false
    var pdfURL: URL?
    var showShareSheet: Bool = false
    var isFreeProfile: Bool = !ProfileManager.shared.profile.role.boolValue
  }
}
