//
//  AdTrackerWidgetBundle.swift
//  AdTrackerWidget
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import WidgetKit
import SwiftUI

@main
struct AdTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        AdTrackerWidget()
        AdTrackerWidgetControl()
        AdTrackerWidgetLiveActivity()
    }
}
