//
//  GeneralView.swift
//  ColorPalette
//
//  Created by Кирилл Колесников on 30.11.2022.
//

import SwiftUI

struct GeneralView: View {
  @StateObject var viewModel: GeneralViewModel
  @EnvironmentObject private var localizationService: LocalizationService

  var body: some View {
    VStack {
      header
      ScrollView {
        paletteCells
        colorsCells
      }
    }
    .onAppear(perform: onAppear)
    .padding([.top, .bottom])
    .foregroundColor(.primary)
  }
}

private extension GeneralView {
  private var header: some View {
    HStack {
      Text(.general)
        .bold()
        .font(.largeTitle)
      Spacer()
      headerButtons

    }
    .padding([.leading, .trailing])
  }

  private var headerButtons: some View {
    HStack {
      Button(action: { navigateToCameraDetection() }) {
        Image(systemName: "camera")
          .resizable()
          .frame(width: 25, height: 20)
      }
      .padding(.trailing, 25)

      Button(action: { navigateToImageDetection() }) {
        Image(systemName: "photo")
          .resizable()
          .frame(width: 25, height: 20)
      }
    }
    .padding(.trailing)
  }

  private var paletteCells: some View {
    VStack(spacing: 0) {
      HStack {
        Text(.palettes)
          .font(.title3.bold())
        Spacer()
      }
      .padding(.bottom, 5)

      ForEach(viewModel.output.samplePalettes) { palette in
        ColorPaletteCell(palette: palette)
          .onTapGesture { navigateToPaletteInfo(palette) }
      }
      Button(action: { navigateToSamplePalettes() }) {
        Text(.showMore)
      }
      .padding()
    }
    .padding([.leading, .trailing])
  }

  private var colorsCells: some View {
    VStack(spacing: 0) {
      HStack {
        Text(.colors).font(.title3.bold())
        Spacer()
      }
      .padding(.bottom, 5)

      ForEach(viewModel.output.sampleColors) { color in
        Color(color)
          .opacity(color.alpha)
          .frame(height: 35)
          .cornerRadius(7)
          .padding([.top, .bottom], 10)
          .onTapGesture { navigateToColorInfo(color) }
      }

      Button(action: { navigateToSampleColors() }) {
        Text(.showMore)
      }
      .padding()
    }
    .padding([.leading, .trailing])
  }
}

private extension GeneralView {
  private func onAppear() {
    viewModel.input.onAppear.send()
  }

  private func navigateToSamplePalettes() {
    viewModel.input.showMorePalettesTap.send()
  }

  private func navigateToSampleColors() {
    viewModel.input.showMoreColorsTap.send()
  }

  private func navigateToPaletteInfo(_ palette: ColorPalette) {
    viewModel.input.paletteTap.send(palette)
  }

  private func navigateToColorInfo(_ color: AppColor) {
    viewModel.input.colorTap.send(color)
  }

  private func navigateToCameraDetection() {
    viewModel.input.cameraDetectionTap.send()
  }

  private func navigateToImageDetection() {
    viewModel.input.imageDetectionTap.send()
  }
}

struct GeneralView_Previews: PreviewProvider {
  static var previews: some View {
    GeneralView(viewModel: GeneralViewModel())
      .environmentObject(LocalizationService.shared)
  }
}
