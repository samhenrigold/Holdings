//
//  Design+Const.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

enum Design {
    static let CurrencyStyle: Decimal.FormatStyle.Currency = .currency(code: "USD").rounded(rule: .up, increment: 1)
}

// MARK: - Currency Text Helper

extension Text {
    /// Creates a Text view displaying a currency value using the app's standard currency style.
    init(currency value: Int) {
        self.init(Decimal(value), format: Design.CurrencyStyle)
    }
    
    /// Creates a Text view displaying a currency value with a sign prefix.
    init(currencyChange value: Int) {
        if value >= 0 {
            self.init("+\(Decimal(value).formatted(Design.CurrencyStyle))")
        } else {
            self.init(Decimal(value), format: Design.CurrencyStyle)
        }
    }
}
