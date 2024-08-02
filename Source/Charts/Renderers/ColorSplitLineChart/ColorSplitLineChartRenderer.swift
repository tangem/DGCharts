//
//  ColorSplitLineChartRenderer.swift
//  Tangem
//
//  Created by Andrey Fedorov on 31.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CoreGraphics
import DGCharts

public final class ColorSplitLineChartRenderer: LineChartRenderer {
    public weak var delegate: ColorSplitLineChartRendererDelegate?

    private var chartView: ChartViewBase? { dataProvider as? ChartViewBase }

    override public func drawHighlighted(context: CGContext, indices: [Highlight]) {
        super.drawHighlighted(context: context, indices: indices)

        guard
            !indices.isEmpty,
            let dataProvider = dataProvider,
            let lineData = dataProvider.lineData
        else {
            return
        }

        let phaseY = animator.phaseY

        context.saveGState()
        defer { context.restoreGState() }

        for highlight in indices {
            guard
                let dataSet = lineData.dataSets[highlight.dataSetIndex] as? ColorSplitLineChartDataSet,
                dataSet.isVisible,
                dataSet.isDrawHighlightCircleEnabled
            else {
                continue
            }

            let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
            let valueToPixelMatrix = trans.valueToPixelMatrix

            let centerPoint = CGPoint(
                x: highlight.x,
                y: CGFloat(highlight.y * phaseY)
            ).applying(valueToPixelMatrix)

            guard
                viewPortHandler.isInBoundsLeft(centerPoint.x),
                viewPortHandler.isInBoundsRight(centerPoint.x),
                viewPortHandler.isInBoundsY(centerPoint.y)
            else {
                continue
            }

            let outerRect = CGRect(center: centerPoint, dimension: dataSet.outerHighlightCircleRadius * 2.0)
            let outerRectColor = dataSet.outerHighlightCircleColor.withAlphaComponent(dataSet.outerHighlightCircleAlpha)

            let innerRect = CGRect(center: centerPoint, dimension: dataSet.innerHighlightCircleRadius * 2.0)
            let innerRectColor = dataSet.innerHighlightCircleColor.withAlphaComponent(dataSet.innerHighlightCircleAlpha)
            let holeRect = CGRect(center: centerPoint, dimension: dataSet.highlightCircleHoleRadius * 2.0)

            context.beginPath()

            // Draw an outer circle of radius `outerHighlightCircleRadius` with
            // a transparent hole of radius `innerHighlightCircleRadius` inside it
            context.saveGState()
            context.setFillColor(outerRectColor.cgColor)
            context.addEllipse(in: outerRect)
            context.addEllipse(in: innerRect)
            context.fillPath(using: .evenOdd)
            context.restoreGState()

            // Draw an inner circle of radius `innerHighlightCircleRadius` with
            // a transparent hole of radius `highlightCircleHoleRadius` inside it
            context.setFillColor(innerRectColor.cgColor)
            context.addEllipse(in: innerRect)
            context.addEllipse(in: holeRect)
            context.fillPath(using: .evenOdd)
        }
    }

    /// - Note: The implementation is loosely based on the implementation of the parent class,
    /// `LineChartRenderer.drawLinear(context:dataSet:)`.
    override public func drawLinear(context: CGContext, dataSet: LineChartDataSetProtocol) {
        guard let dataProvider = dataProvider else {
            return
        }

        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)

        let valueToPixelMatrix = trans.valueToPixelMatrix

        let entryCount = dataSet.entryCount
        let isDrawSteppedEnabled = dataSet.mode == .stepped
        let pointsPerEntryPair = isDrawSteppedEnabled ? 4 : 2

        let phaseY = animator.phaseY

        _xBounds.set(chart: dataProvider, dataSet: dataSet, animator: animator)

        // if drawing filled is enabled
        if dataSet.isDrawFilledEnabled, entryCount > 0 {
            drawLinearFill(context: context, dataSet: dataSet, trans: trans, bounds: _xBounds)
        }

        context.saveGState()
        defer { context.restoreGState() }

        // more than 1 color
        if dataSet.colors.count > 1, !dataSet.isDrawLineWithGradientEnabled {
            assertionFailure("Data sets with multiple color are not supported by this renderer")
        } else { // only one color per dataset
            guard dataSet.entryForIndex(_xBounds.min) != nil else {
                return
            }

            guard let chartView else {
                assertionFailure("Unable to obtain an associated chart view")
                return
            }

            if let lastHighlighted = chartView.lastHighlighted,
               let highlightedEntry = dataSet.entryForXValue(
                lastHighlighted.x,
                closestToY: lastHighlighted.y,
                rounding: .closest
               ),
               let segmentAppearanceBefore = delegate?.segmentAppearanceBefore(
                highlightedEntry: highlightedEntry,
                highlight: lastHighlighted,
                renderer: self
               ),
               let segmentAppearanceAfter = delegate?.segmentAppearanceAfter(
                highlightedEntry: highlightedEntry,
                highlight: lastHighlighted,
                renderer: self
               ) {
                let highlightedEntryIndex = dataSet.entryIndex(entry: highlightedEntry)
                // The part of line before the highlight
                drawLinearSegment(
                    context: context,
                    dataSet: dataSet,
                    from: _xBounds.min,
                    through: highlightedEntryIndex + _xBounds.min,
                    color: segmentAppearanceBefore.lineColor.cgColor,
                    valueToPixelMatrix: valueToPixelMatrix,
                    phaseY: phaseY,
                    isDrawSteppedEnabled: isDrawSteppedEnabled
                )
                // The part of line after the highlight
                drawLinearSegment(
                    context: context,
                    dataSet: dataSet,
                    from: highlightedEntryIndex + 1,
                    through: _xBounds.range + _xBounds.min,
                    color: segmentAppearanceAfter.lineColor.cgColor,
                    valueToPixelMatrix: valueToPixelMatrix,
                    phaseY: phaseY,
                    isDrawSteppedEnabled: isDrawSteppedEnabled
                )
            } else {
                drawLinearSegment(
                    context: context,
                    dataSet: dataSet,
                    from: _xBounds.min,
                    through: _xBounds.range + _xBounds.min,
                    color: dataSet.color(atIndex: 0).cgColor,
                    valueToPixelMatrix: valueToPixelMatrix,
                    phaseY: phaseY,
                    isDrawSteppedEnabled: isDrawSteppedEnabled
                )
            }
        }
    }

    override public func drawLinearFill(
        context: CGContext,
        dataSet: LineChartDataSetProtocol,
        trans: Transformer,
        bounds: BarLineScatterCandleBubbleRenderer.XBounds
    ) {
        guard let dataProvider = dataProvider else {
            return
        }

        let fillMin = dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0
        var filledPaths: [CGPath] = []
        var fillForPath: [CGPath: Fill] = [:]
        var fillAlphaForPath: [CGPath: CGFloat] = [:]

        guard let chartView else {
            assertionFailure("Unable to obtain an associated chart view")
            return
        }

        if let lastHighlighted = chartView.lastHighlighted,
           let highlightedEntry = dataSet.entryForXValue(
            lastHighlighted.x,
            closestToY: lastHighlighted.y,
            rounding: .closest
           ),
           let segmentAppearanceBefore = delegate?.segmentAppearanceBefore(
            highlightedEntry: highlightedEntry,
            highlight: lastHighlighted,
            renderer: self
           ),
           let segmentAppearanceAfter = delegate?.segmentAppearanceAfter(
            highlightedEntry: highlightedEntry,
            highlight: lastHighlighted,
            renderer: self
           ) {
            let highlightedEntryIndex = dataSet.entryIndex(entry: highlightedEntry)
            // gradient before the highlight
            let filledPathBeforeHighlight = generateFilledPath(
                dataSet: dataSet,
                fillMin: fillMin,
                min: bounds.min,
                range: highlightedEntryIndex,
                matrix: trans.valueToPixelMatrix
            )
            // gradient after the highlight
            let filledPathAfterHighlight = generateFilledPath(
                dataSet: dataSet,
                fillMin: fillMin,
                min: highlightedEntryIndex,
                range: bounds.range - highlightedEntryIndex,
                matrix: trans.valueToPixelMatrix
            )

            filledPaths.append(filledPathBeforeHighlight)
            filledPaths.append(filledPathAfterHighlight)

            fillForPath[filledPathBeforeHighlight] = segmentAppearanceBefore.fill
            fillForPath[filledPathAfterHighlight] = segmentAppearanceAfter.fill

            fillAlphaForPath[filledPathBeforeHighlight] = segmentAppearanceBefore.fillAlpha
            fillAlphaForPath[filledPathAfterHighlight] = segmentAppearanceAfter.fillAlpha
        } else if let fill = dataSet.fill {
            let filledPath = generateFilledPath(
                dataSet: dataSet,
                fillMin: fillMin,
                min: bounds.min,
                range: bounds.range,
                matrix: trans.valueToPixelMatrix
            )

            filledPaths.append(filledPath)
            fillForPath[filledPath] = dataSet.fill
            fillAlphaForPath[filledPath] = dataSet.fillAlpha
        } else {
            filledPaths.append(
                generateFilledPath(
                    dataSet: dataSet,
                    fillMin: fillMin,
                    min: bounds.min,
                    range: bounds.range,
                    matrix: trans.valueToPixelMatrix
                )
            )
        }

        for path in filledPaths {
            if let fill = fillForPath[path], let fillAlpha = fillAlphaForPath[path] {
                drawFilledPath(context: context, path: path, fill: fill, fillAlpha: fillAlpha)
            } else {
                drawFilledPath(context: context, path: path, fillColor: dataSet.fillColor, fillAlpha: dataSet.fillAlpha)
            }
        }
    }

    /// - Note: The implementation is loosely based on the implementation of the parent class,
    /// `LineChartRenderer.drawLinear(context:dataSet:)`.
    private func drawLinearSegment(
        context: CGContext,
        dataSet: LineChartDataSetProtocol,
        from: Int,
        through: Int,
        color: CGColor,
        valueToPixelMatrix: CGAffineTransform,
        phaseY: Double,
        isDrawSteppedEnabled: Bool
    ) {
        var firstPoint = true

        let path = CGMutablePath()

        for x in stride(from: from, through: through, by: 1) {
            guard let e1 = dataSet.entryForIndex(x == 0 ? 0 : (x - 1)) else { continue }
            guard let e2 = dataSet.entryForIndex(x) else { continue }

            let startPoint =
            CGPoint(
                x: CGFloat(e1.x),
                y: CGFloat(e1.y * phaseY)
            )
            .applying(valueToPixelMatrix)

            if firstPoint {
                path.move(to: startPoint)
                firstPoint = false
            } else {
                path.addLine(to: startPoint)
            }

            if isDrawSteppedEnabled {
                let steppedPoint =
                CGPoint(
                    x: CGFloat(e2.x),
                    y: CGFloat(e1.y * phaseY)
                )
                .applying(valueToPixelMatrix)
                path.addLine(to: steppedPoint)
            }

            let endPoint =
            CGPoint(
                x: CGFloat(e2.x),
                y: CGFloat(e2.y * phaseY)
            )
            .applying(valueToPixelMatrix)
            path.addLine(to: endPoint)
        }

        if !firstPoint {
            if dataSet.isDrawLineWithGradientEnabled {
                drawGradientLine(context: context, dataSet: dataSet, spline: path, matrix: valueToPixelMatrix)
            } else {
                context.beginPath()
                context.addPath(path)
                context.setStrokeColor(color)
                context.strokePath()
            }
        }
    }

    /// Generates the path that is used for filled drawing.
    ///
    /// - Note: The implementation is loosely based on the implementation of the parent class,
    /// `LineChartRenderer.generateFilledPath(dataSet:fillMin:bounds:matrix:)`.
    private func generateFilledPath(
        dataSet: LineChartDataSetProtocol,
        fillMin: CGFloat,
        min: Int,
        range: Int,
        matrix: CGAffineTransform
    ) -> CGPath {
        let phaseY = animator.phaseY
        let isDrawSteppedEnabled = dataSet.mode == .stepped
        let matrix = matrix

        var e: ChartDataEntry!

        let filled = CGMutablePath()

        e = dataSet.entryForIndex(min)
        if e != nil {
            filled.move(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
        }

        // create a new path
        for x in stride(from: min + 1, through: range + min, by: 1) {
            guard let e = dataSet.entryForIndex(x) else { continue }

            if isDrawSteppedEnabled {
                guard let ePrev = dataSet.entryForIndex(x - 1) else { continue }
                filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(ePrev.y * phaseY)), transform: matrix)
            }

            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y * phaseY)), transform: matrix)
        }

        // close up
        e = dataSet.entryForIndex(range + min)
        if e != nil {
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
        }
        filled.closeSubpath()

        return filled
    }
}
