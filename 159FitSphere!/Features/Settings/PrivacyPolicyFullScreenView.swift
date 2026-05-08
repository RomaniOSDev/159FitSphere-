import SwiftUI

struct PrivacyPolicyFullScreenView: View {
    @Binding var isPresented: Bool

    let markdown: String

    var body: some View {
        NavigationStack {
            ZStack {
                AppChromeBackground()

                ScrollView {
                    Group {
                        if let attributed = try? AttributedString(
                            markdown: markdown,
                            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
                        ) {
                            Text(attributed)
                                .foregroundStyle(Color.appTextPrimary)
                                .tint(Color.appPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(markdown)
                                .foregroundStyle(Color.appTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        HapticSound.tapLight()
                        isPresented = false
                    }
                    .foregroundStyle(Color.appTextPrimary)
                }
            }
            .tint(Color.appPrimary)
        }
    }
}
