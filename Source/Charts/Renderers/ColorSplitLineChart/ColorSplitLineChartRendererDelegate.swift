//
//  ColorSplitLineChartRendererDelegate.swift
//  Tangem
//
//  Created by Andrey Fedorov on 31.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol ColorSplitLineChartRendererDelegate: AnyObject {
    // TODO: Andrey Fedorov - replace entryIndex with highlight!
    func segmentAppearanceBeforeHighlightedEntry(
        atIndex entryIndex: Int,
        renderer: ColorSplitLineChartRenderer
    ) -> ColorSplitLineChartSegmentAppearance?

    func segmentAppearanceAfterHighlightedEntry(
        atIndex entryIndex: Int,
        renderer: ColorSplitLineChartRenderer
    ) -> ColorSplitLineChartSegmentAppearance?
}
