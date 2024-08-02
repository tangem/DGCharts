//
//  ColorSplitLineChartRendererDelegate.swift
//  Tangem
//
//  Created by Andrey Fedorov on 31.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol ColorSplitLineChartRendererDelegate: AnyObject {
    func segmentAppearanceBefore(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        renderer: ColorSplitLineChartRenderer
    ) -> ColorSplitLineChartSegmentAppearance?

    func segmentAppearanceAfter(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        renderer: ColorSplitLineChartRenderer
    ) -> ColorSplitLineChartSegmentAppearance?
}
