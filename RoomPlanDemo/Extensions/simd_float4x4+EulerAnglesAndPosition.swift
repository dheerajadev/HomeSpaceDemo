//
//  simd_float4x4+EulerAnglesAndPosition.swift
//  RoomPlanDemo
//
//  Created by Appscrip 3Embed on 06/02/25.
//

import SceneKit

extension simd_float4x4 {
    
    var eulerAngles: simd_float3 {
        simd_float3(
            x: asin(-self[2][1]),
            y: atan2(self[2][0], self[2][2]),
            z: atan2(self[0][1], self[1][1])
        )
    }

    var position: simd_float3 {
        simd_float3(
            x: self.columns.3.x,
            y: self.columns.3.y,
            z: self.columns.3.z
        )
    }
    
}
