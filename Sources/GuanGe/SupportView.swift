import AppKit
import SwiftUI

struct SupportView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 14) {
            Text(model.localized("联系和打赏作者", "Contact & Support the Author"))
                .font(.title2.bold())
            HStack(spacing: 16) {
                paymentImage("支付宝收款码")
                paymentImage("微信打赏码")
            }
            Text(model.localized(
                "感谢您的赞赏，如有意见和建议请联系作者：xingheyaoshi@163.com",
                "Thank you for your support. Feedback and suggestions: xingheyaoshi@163.com"
            ))
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(20)
        .frame(minWidth: 820, minHeight: 570)
    }

    @ViewBuilder
    private func paymentImage(_ name: String) -> some View {
        if let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 380, maxHeight: 490)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.largeTitle)
                Text(model.localized("图片未找到", "Image not found"))
                    .font(.headline)
                Text(name)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 360, height: 450)
        }
    }
}
