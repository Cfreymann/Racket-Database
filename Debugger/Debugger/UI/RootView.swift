import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        ZStack {
            switch app.screen {
            case .menu:
                MenuView()
                    .transition(.opacity)
            case .game(let levelIndex, let runID):
                let level = app.level(at: levelIndex)
                GameView(
                    levelIndex: levelIndex,
                    level: level,
                    swatter: app.swatter,
                    spray: app.spray,
                    sprayEnabled: level.sprayEnabled && app.isSprayUnlocked,
                    onFinish: { result in app.complete(result) },
                    onQuit: { app.goToMenu() }
                )
                .id(runID)
                .transition(.opacity)
            case .results(let result):
                ResultsView(result: result)
                    .transition(.opacity)
            case .failed(let result):
                FailView(result: result)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: app.screen)
        .sheet(isPresented: $app.showShop, onDismiss: { app.shopDismissed() }) {
            ShopView()
                .environmentObject(app)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
