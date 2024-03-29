//
//  ColorInfoViewModel.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 10.02.2023.
//

import Foundation
import Combine

final class ColorInfoViewModel: ObservableObject {
  typealias FavoriteService = FavoritesAddServiceProtocol & FavoritesDeleteServiceProtocol

  let input: Input
  @Published var output: Output

  private let favoritesManager: FavoriteManager
  private let service: FavoriteService
  private let color: AppColor

  private var cancellable: Set<AnyCancellable> = .init()

  init(
    color: AppColor,
    service: FavoriteService = FavoritesNetworkService.shared
  ) {
    self.input = Input()
    self.output = Output()

    self.color = color
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

private extension ColorInfoViewModel {
  private func bindRequests() {
    input.onAppear
      .map { [unowned self] _ -> Bool in
        checkFavorite(color: self.color)
      }
      .sink { [unowned self] isFavorite in
        output.isFavorite = isFavorite
      }
      .store(in: &cancellable)

    input.favTap
      .filter { [unowned self] _ in
        !CredentialsManager.shared.isGuest && output.isFavorite
      }
      .flatMap { [unowned self] _ -> AnyPublisher<Void, ApiError> in
        service.deleteColor(colorId: color.id)
      }
      .sink { response in
        switch response {
        case let .failure(apiError):
          print("\(apiError.localizedDescription)")
        case .finished:
          print("finished")
        }
      } receiveValue: { [unowned self] _ in
        favoritesManager.removeColor(color)
        output.isFavorite.toggle()
      }
      .store(in: &cancellable)

    input.favTap
      .filter { [unowned self] _ in
        !CredentialsManager.shared.isGuest && (!output.isFavorite && !favoritesManager.isColorsLimit)
      }
      .flatMap { [unowned self] _ -> AnyPublisher<Void, ApiError> in
        service.addColor(color: color)
      }
      .sink { response in
        switch response {
        case let .failure(apiError):
          print("\(apiError.localizedDescription)")
        case .finished:
          print("finished")
        }
      } receiveValue: { [unowned self] _ in
        favoritesManager.addColor(color)
        output.isFavorite.toggle()
      }
      .store(in: &cancellable)

    input.favTap
      .filter { _ in CredentialsManager.shared.isGuest }
      .sink { [unowned self] _ in
        changeFavoriteState()
      }
      .store(in: &cancellable)

  }

  private func checkFavorite(color: AppColor) -> Bool {
    favoritesManager
      .colors
      .contains(where: {
        $0.hex == color.hex &&
        $0.name == color.name
      })
  }

  private func changeFavoriteState() {
    if output.isFavorite {
      favoritesManager.removeColor(color)
      output.isFavorite.toggle()
    } else {
      if !favoritesManager.isColorsLimit {
        favoritesManager.addColor(color)
        output.isFavorite.toggle()
      }
    }
  }
}

extension ColorInfoViewModel {
  struct Input {
    let onAppear: PassthroughSubject<Void, Never> = .init()
    let favTap: PassthroughSubject<Void, Never> = .init()
  }

  struct Output {
    var isFavorite: Bool = false
    var pdfURL: URL?
    var showShareSheet: Bool = false
  }
}
