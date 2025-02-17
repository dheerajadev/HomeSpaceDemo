//
//  DrawParameters.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import UIKit

// Universal scaling factor
let scalingFactor: CGFloat = 100

// Colors
let floorPlanBackgroundColor = UIColor.white
let floorPlanSurfaceColor = UIColor(hex: "#004792")!
let dimensionTextColor = UIColor.black
let windowColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)  // Light blue
let doorColor = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)    // Green
let openingColor = UIColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1.0) // Orange
let objectColor = UIColor.darkGray

// Line widths
let surfaceWith: CGFloat = 6.0
let hideSurfaceWith: CGFloat = 8.0
let windowWidth: CGFloat = 2.0
let doorArcWidth: CGFloat = 2.0
let objectOutlineWidth: CGFloat = 2.0
let dimensionLineWidth: CGFloat = 2.0

// Font
let dimensionFontSize: CGFloat = 14.0

// Dimension
let dimensionOffset: CGFloat = 30.0
let dimensionCapLength: CGFloat = 8.0

// zPositions
let hideSurfaceZPosition: CGFloat = 1
let windowZPosition: CGFloat = 10
let doorZPosition: CGFloat = 20
let doorArcZPosition: CGFloat = 21
let objectZPosition: CGFloat = 30
let objectOutlineZPosition: CGFloat = 31
let dimensionZPosition: CGFloat = 40
