//
//  ProfileViewModel.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 31.12.2022.
//

import Foundation
import Combine

final class ProfileViewModel: ObservableObject {
  typealias Routable = AuthorizationRoutable & ColorPsychologyRoutable & SubscribtionsPlanInfoRoutable

  let input: Input
  @Published var output: Output

  private let profileManager: ProfileManager
  private let service: ProfileServiceProtocol
  private weak var router: Routable?

  private var cancellable: Set<AnyCancellable> = .init()

  init(
    router: Routable? = nil,
    service: ProfileServiceProtocol = AuthorizationNetworkService.shared
  ) {
    self.input = Input()
    self.output = Output()
    self.router = router
    self.service = service
    self.profileManager = ProfileManager.shared

    bindProfile()
    bindTaps()

    print("\(self) INIT")
  }

  deinit {
    cancellable.forEach { $0.cancel() }
    cancellable.removeAll()

    print("\(self) DEINIT")
  }
}

private extension ProfileViewModel {
  private func bindProfile() {
    input.onAppear
      .filter { _ in !CredentialsManager.shared.isGuest }
      .flatMap { [unowned self] _ -> AnyPublisher<Profile, ApiError>  in
        service.fetchProfile()
      }
      .sink { [unowned self] response in
        switch response {
        case let .failure(apiError):
          print(apiError.localizedDescription)
          profileManager.logOut()
          output.email = ""
          output.role = .free
        case .finished:
          print("finished")
        }
      } receiveValue: { [unowned self] profile in
        profileManager.setProfile(profile)
      }
      .store(in: &cancellable)

    profileManager.$profile
      .sink { [unowned self] profile in
        output.email = profile.email
        output.role = profile.role
      }
      .store(in: &cancellable)
  }

  private func bindTaps() {
    input.languageTap
      .sink { language in LocalizationService.shared.language = language }
      .store(in: &cancellable)

    input.colorPsychologyTap
      .sink { [unowned self] _ in
        router?.navigateToColorPsychologyScreen()
      }
      .store(in: &cancellable)

    input.showSubscribtionPlansTap
      .sink { [unowned self] _ in
        router?.navigateToSubscribtionsPlanInfoScreen()
      }
      .store(in: &cancellable)

    input.signInTap
      .sink { [unowned self] _ in
        router?.navigateToAuthorizationScreen()
      }
      .store(in: &cancellable)

    input.logOutTap
      .sink { [unowned self] _ in
        profileManager.logOut()
      }
      .store(in: &cancellable)
  }
}

extension ProfileViewModel {
  struct Input {
    let onAppear: PassthroughSubject<Void, Never> = .init()

    let languageTap: PassthroughSubject<Language, Never> = .init()
    let colorPsychologyTap: PassthroughSubject<Void, Never> = .init()
    let showSubscribtionPlansTap: PassthroughSubject<Void, Never> = .init()

    let signInTap: PassthroughSubject<Void, Never> = .init()
    let logOutTap: PassthroughSubject<Void, Never> = .init()
  }

  struct Output {
    var email: String = ""
    var role: Role = .free
    var language: Language = LocalizationService.shared.language
  }
}
