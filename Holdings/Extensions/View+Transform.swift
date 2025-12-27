//
//  View+Transform.swift
//  Holdings
//
//  Created by Sam on 2025-12-23.
//

import SwiftUI

// https://x.com/Barbapapapps/status/2002762692801737183/photo/1
extension View {
    func transform(@ViewBuilder content: (_ view: Self) -> some View) -> some View {
        content(self)
    }
}
