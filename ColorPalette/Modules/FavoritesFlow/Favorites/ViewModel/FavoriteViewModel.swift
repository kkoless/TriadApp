//
//  FavoriteViewModel.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 27.12.2022.
//

import Foundation
import Combine

final class FavoriteViewModel: ObservableObject {
  typealias FavoriteService = FavoritesFetchServiceProtocol & FavoritesAddServiceProtocol & FavoritesDeleteServiceProtocol
  typealias Routable = EditRoutable & AddRoutable & DetectionRoutable & LibraryRoutable & InfoRoutable

  let input: Input
  @Published var output: Output

  private let favoriteManager: FavoriteManager
  private let service: FavoriteService
  private weak var router: Routable?
  private var cancellable: Set<AnyCancellable> = .init()

  init(
    router: Routable? = nil,
    service: FavoriteService = FavoritesNetworkService.shared
  ) {
    self.favoriteManager = FavoriteManager.shared
    self.service = service

    self.input = Input()
    self.output = Output(
      palettes: self.favoriteManager.palettes,
      colors: self.favoriteManager.colors,
      palettesLimit: self.favoriteManager.isPalettesLimit,
      colorsLimit: self.favoriteManager.isColorsLimit
    )

    self.router = router

    bindRequests()
    bindFavoriteManager()
    bindTaps()

    print("\(self) INIT")
  }

  deinit {
    print("\(self) DEINIT")

    cancellable.forEach { $0.cancel() }
    cancellable.removeAll()
  }
}

private extension FavoriteViewModel {
  private func bindRequests() {
    input.onAppear
      .filter { _ in !CredentialsManager.shared.isGuest }
      .flatMap { [unowned self] _ -> AnyPublisher<([AppColor], [ColorPalette]), ApiError> in
        Publishers.Zip(
          self.service.fetchColors(),
          self.service.fetchPalettes()
        )
        .eraseToAnyPublisher()
      }
      .sink { response in
        switch response {
        case let .failure(apiError):
          print(apiError.localizedDescription)
        case .finished:
          print("finished")
        }
      } receiveValue: { [unowned self] items in
        favoriteManager.setItemsFromServer(
          colors: items.0,
          palettes: items.1
        )
      }
      .store(in: &cancellable)

    input.onAppear
      .filter { _ in CredentialsManager.shared.isGuest }
      .sink { [unowned self] _ in
        favoriteManager.setItemsFromCoreData()
      }
      .store(in: &cancellable)
  }

  private func bindFavoriteManager() {
    favoriteManager.$palettes
      .sink { [unowned self] palettes in
        output.palettes = palettes
      }
      .store(in: &cancellable)

    favoriteManager.$colors
      .sink { [unowned self] colors in
        output.colors = colors
      }
      .store(in: &cancellable)

    favoriteManager.$isColorsLimit
      .sink { [unowned self] flag in
        output.colorsLimit = flag
      }
      .store(in: &cancellable)

    favoriteManager.$isPalettesLimit
      .sink { [unowned self] flag in
        output.palettesLimit = flag
      }
      .store(in: &cancellable)
  }

  private func bindTaps() {
    bindAddPaletteTaps()
    bindAddColorTaps()
    bindShowTaps()

    input.editPaletteTap
      .sink { [unowned self] palette in
        router?.navigateToEditPalette(palette: palette)
      }
      .store(in: &cancellable)
  }
}

private extension FavoriteViewModel {
  private func bindAddPaletteTaps() {
    input.addTaps.createPaletteTap
      .sink { [unowned self] _ in
        router?.navigateToCreatePalette()
      }
      .store(in: &cancellable)

    input.addTaps.choosePaletteTap
      .sink { [unowned self] _ in
        router?.navigateToPaletteLibrary()
      }
      .store(in: &cancellable)

    input.addTaps.generatePaletteFromImageTap
      .sink { [unowned self] _ in
        router?.navigateToImageColorDetection()
      }
      .store(in: &cancellable)
  }

  private func bindAddColorTaps() {
    input.addTaps.chooseColorTap
      .sink { [unowned self] _ in
        router?.navigateToColorLibrary()
      }
      .store(in: &cancellable)

    input.addTaps.generateColorFromCameraTap
      .sink { [unowned self] _ in
        router?.navigateToCameraColorDetection()
      }
      .store(in: &cancellable)

    input.addTaps.createColorTap
      .sink { [unowned self] _ in
        router?.navigateToAddNewColorToFavorites()
      }
      .store(in: &cancellable)
  }

  private func bindShowTaps() {
    input.showTaps.showColorInfoTap
      .sink { [unowned self] appColor in
        router?.navigateToColorInfo(color: appColor)
      }
      .store(in: &cancellable)

    input.showTaps.showPaletteInfoTap
      .sink { [unowned self] palette in
        router?.navigateToColorPalette(palette: palette)
      }
      .store(in: &cancellable)
  }
}

private extension FavoriteViewModel {
  private func removeServerPalette(_ palette: ColorPalette) {
    self.service.deletePalette(paletteId: palette.id)
      .sink { response in
        switch response {
        case let .failure(apiError):
          print(apiError.localizedDescription)
        case .finished:
          print("finished")
        }
      } receiveValue: { [unowned self] _ in
        favoriteManager.removePalette(palette)
      }
      .store(in: &cancellable)
  }

  private func removeServerColor(_ color: AppColor) {
    self.service.deleteColor(colorId: color.id)
      .sink { response in
        switch response {
        case let .failure(apiError):
          print(apiError.localizedDescription)
        case .finished:
          print("finished")
        }
      } receiveValue: { [unowned self] _ in
        favoriteManager.removeColor(color)
      }
      .store(in: &cancellable)
  }

  private func removeLocalPalette(_ palette: ColorPalette) {
    self.favoriteManager.removePalette(palette)
  }

  private func removeLocalColor(_ color: AppColor) {
    self.favoriteManager.removeColor(color)
  }
}

extension FavoriteViewModel {
  func removePalette(from index: Int) {
    let paletteForDelete = output.palettes[index]

    if CredentialsManager.shared.isGuest {
      removeLocalPalette(paletteForDelete)
    } else {
      removeServerPalette(paletteForDelete)
    }
  }

  func removeColor(from index: Int) {
    let colorForDelete = output.colors[index]

    if CredentialsManager.shared.isGuest {
      removeLocalColor(colorForDelete)
    } else {
      removeServerColor(colorForDelete)
    }
  }
}

extension FavoriteViewModel {
  struct Input {
    let onAppear: PassthroughSubject<Void, Never> = .init()
    let editPaletteTap: PassthroughSubject<ColorPalette, Never> = .init()
    let addTaps: AddTap = .init()
    let showTaps: ShowTap = .init()

    struct AddTap {
      let createPaletteTap: PassthroughSubject<Void, Never> = .init()
      let choosePaletteTap: PassthroughSubject<Void, Never> = .init()
      let generatePaletteFromImageTap: PassthroughSubject<Void, Never> = .init()
      let createColorTap: PassthroughSubject<Void, Never> = .init()
      let chooseColorTap: PassthroughSubject<Void, Never> = .init()
      let generateColorFromCameraTap: PassthroughSubject<Void, Never> = .init()
    }

    struct ShowTap {
      let showColorInfoTap: PassthroughSubject<AppColor, Never> = .init()
      let showPaletteInfoTap: PassthroughSubject<ColorPalette, Never> = .init()
    }
  }

  struct Output {
    var palettes: [ColorPalette]
    var colors: [AppColor]
    var palettesLimit: Bool
    var colorsLimit: Bool
  }
}

enum FavoriteAddType {
  case customPalette
  case libraryPalette
  case paletteFromImage

  case customColor
  case libraryColor
  case colorFromCamera
}
