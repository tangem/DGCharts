//
//  LineChartContainerViewController.swift
//  Tangem
//
//  Created by Andrey Fedorov on 22.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

public final class LineChartContainerViewController: UIViewController {
    public private(set) lazy var lineChartView = LineChartView()

    private lazy var coreAnimationDrawingView = LineChartCoreAnimationDrawingView()

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    private func setupSubviews() {
        // `coreAnimationDrawingView` must lie underneath the `lineChartView` for the chart to be drawn correctly
        setupSubview(coreAnimationDrawingView)
        setupSubview(lineChartView)
    }

    private func setupSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subview.topAnchor.constraint(equalTo: view.topAnchor),
            subview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - LineChartPathHandler protocol conformance

extension LineChartContainerViewController: LineChartPathHandler {
    public func handlePath(_ path: CGPath, with settings: LineChartDrawingPathSettings) {
        let lastHighlightedPoint: CGPoint?

        if let lastHighlighted = lineChartView.lastHighlighted {
            lastHighlightedPoint = CGPoint(x: lastHighlighted.drawX, y: lastHighlighted.drawY)
        } else {
            lastHighlightedPoint = nil
        }

        coreAnimationDrawingView.setDrawingPath(path, settings: settings, lastHighlightedPoint: lastHighlightedPoint)
    }
}
