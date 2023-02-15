//
//  FavoritesAPI.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 10.02.2023.
//

import Foundation
import Moya

enum FavoritesAPI {
    case addColor(color: AppColor)
    case deleteColor(colorId: Int)
    case getColors
    
    case addPalette(palette: ColorPalette)
    case deletePalette(paletteId: Int)
    case updatePalette(paletteForDelete: Int, newPalette: ColorPalette)
    case getPalettes
}

extension FavoritesAPI: TargetType {
    var baseURL: URL {
        Consts.API.baseUrl
    }
    
    var path: String {
        switch self {
            case .addColor:
                return "/color/add"
            case .deleteColor:
                return "/color/delete"
            case .getColors:
                return "/colors"
            case .addPalette:
                return "/palette/add"
            case .deletePalette:
                return "/palette/delete"
            case .updatePalette(paletteForDelete: let id, newPalette: _):
                return "/palette/update/\(id)"
            case .getPalettes:
                return "/palettes"
        }
    }
    
    var method: Moya.Method {
        switch self {
            case .addColor, .addPalette, .updatePalette:
                return .post
            case .deleteColor, .deletePalette:
                return .delete
            case .getColors, .getPalettes:
                return .get
        }
    }
    
    var task: Moya.Task {
        var params = [String: Any]()
        
        switch self {
            case .addColor(let color):
                return .requestParameters(parameters: color.getJSON(),
                                          encoding: JSONEncoding.default)
                
            case .deleteColor(colorId: let id):
                params["id"] = id
                return .requestCompositeParameters(bodyParameters: [:], bodyEncoding: JSONEncoding.default, urlParameters: params)
                
            case .getColors, .getPalettes:
                return .requestPlain
                
            case .addPalette(let palette):
                return .requestParameters(parameters: palette.getJSON(),
                                          encoding: JSONEncoding.default)
                
            case .deletePalette(paletteId: let id):
                params["id"] = id
                return .requestCompositeParameters(bodyParameters: [:], bodyEncoding: JSONEncoding.default, urlParameters: params)
            
            case .updatePalette(paletteForDelete: _, newPalette: let palette):
                return .requestParameters(parameters: palette.getJSON(),
                                          encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        var params: [String: String] = .init()
        
        if let token = CredentialsManager.shared.token, !token.isEmpty {
            params[Consts.API.tokenHeader] = "Bearer \(token)"
        }
        
        return params
    }
}
