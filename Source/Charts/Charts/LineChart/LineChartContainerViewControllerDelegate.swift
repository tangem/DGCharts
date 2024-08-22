//
//  LineChartContainerViewControllerDelegate.swift
//  Tangem
//
//  Created by Andrey Fedorov on 22.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol LineChartContainerViewControllerDelegate: AnyObject {
    func segmentAppearanceBefore(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        viewController: LineChartContainerViewController
    ) -> LineChartContainerViewControllerSegmentAppearance?

    func segmentAppearanceAfter(
        highlightedEntry: ChartDataEntry,
        highlight: Highlight,
        viewController: LineChartContainerViewController
    ) -> LineChartContainerViewControllerSegmentAppearance?
}
