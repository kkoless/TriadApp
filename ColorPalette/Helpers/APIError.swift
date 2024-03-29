//
//  APIError.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 08.02.2023.
//

import Foundation

enum ApiError: Error {
  case badRequest(message: String?)
  case network(message: String?)
  case notFound(message: String?)
  case accountNotFound
  case internetDisabled
  case unknown
  
  var message: String? {
    switch self {
    case let .badRequest(message):
      return message
    case let .network(message):
      return message
    case let .notFound(message):
      return message
    case .internetDisabled:
      return "Вероятно, соединение с интернетом прервано."
    case .accountNotFound:
      return "Войдите в аккаунт еще раз"
    case .unknown:
      return "Неизвестная ошибка"
    }
  }
}
