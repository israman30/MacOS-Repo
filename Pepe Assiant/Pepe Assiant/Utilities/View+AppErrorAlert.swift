import SwiftUI

extension View {
    /// Convenience: show an alert for any `AppError?` binding.
    func appErrorAlert(_ error: Binding<AppError?>, buttonTitle: String = "OK") -> some View {
        alert(item: error) { err in
            Alert(
                title: Text(err.title),
                message: Text(err.message),
                dismissButton: .default(Text(buttonTitle))
            )
        }
    }
}

