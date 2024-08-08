//
//  ColorSplitLineChartSegmentAppearance.swift
//  Tangem
//
//  Created by Andrey Fedorov on 31.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public final class ColorSplitLineChartSegmentAppearance {
    /// - Returns: The object that is used for filling the area below the line.
    public var fill: Fill?

    /// The alpha value that is used for filling the line surface.
    public var fillAlpha: CGFloat

    /// The color that is used for filling the line surface area.
    public var lineColor: NSUIColor

    public init(
        fill: Fill?,
        fillAlpha: CGFloat,
        lineColor: NSUIColor
    ) {
        self.fill = fill
        self.fillAlpha = fillAlpha
        self.lineColor = lineColor
    }
}
