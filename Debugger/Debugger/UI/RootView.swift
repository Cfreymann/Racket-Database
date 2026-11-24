import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        ZStack {
            switch app.screen {
            case .menu:
                MenuView()
                    .transition(.opacity)
            case .game(let runID):
                GameView(
                    level: app.currentLevel,
                    swatter: app.swatter,
                    spray: app.spray,
                    onFinish: { result in app.complete(result) },
                    onQuit: { app.goToMenu() }
                )
                .id(runID)
                .transition(.opacity)
            case .results(let result):
                ResultsView(result: result)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.screen)
        .sheet(isPresented: $app.showShop) {
            ShopView()
                .environmentObject(app)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
