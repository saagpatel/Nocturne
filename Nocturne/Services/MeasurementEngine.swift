import CoreVideo
import Foundation

enum MeasurementEngine {

    // MARK: - Pixel Buffer Processing

    /// Computes average luminance in cd/m² from the center crop of a pixel buffer.
    ///
    /// Samples a `PixelConstants.centerCropSize × PixelConstants.centerCropSize` region
    /// at the center of the frame. Expects `kCVPixelFormatType_32BGRA` format.
    /// Uses Rec.709 luma coefficients and sRGB gamma (2.2) for the conversion.
    static func averageLuminance(from pixelBuffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return 0
        }
        let ptr = baseAddress.assumingMemoryBound(to: UInt8.self)

        let cropSize = min(PixelConstants.centerCropSize, min(width, height))
        let startX = (width - cropSize) / 2
        let startY = (height - cropSize) / 2

        var sumLuma: Double = 0
        var sampleCount = 0

        for y in startY..<(startY + cropSize) {
            for x in startX..<(startX + cropSize) {
                let offset = y * bytesPerRow + x * 4 // BGRA: 4 bytes per pixel
                let b = Double(ptr[offset])
                let g = Double(ptr[offset + 1])
                let r = Double(ptr[offset + 2])

                let luma = LumaCoefficients.red * r
                    + LumaCoefficients.green * g
                    + LumaCoefficients.blue * b

                sumLuma += luma
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else { return 0 }

        let meanLuma = sumLuma / Double(sampleCount)
        let normalized = meanLuma / 255.0
        return pow(normalized, PixelConstants.gammaExponent) * PixelConstants.referenceLuminance
    }

    /// Fraction of pixels in the entire frame where R=G=B=255 (saturated).
    /// Returns a value in `[0.0, 1.0]`.
    static func hotPixelFraction(in pixelBuffer: CVPixelBuffer) -> Double {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return 0
        }
        let ptr = baseAddress.assumingMemoryBound(to: UInt8.self)

        var hotCount = 0
        let totalPixels = width * height

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let b = ptr[offset]
                let g = ptr[offset + 1]
                let r = ptr[offset + 2]

                if r == 255, g == 255, b == 255 {
                    hotCount += 1
                }
            }
        }

        guard totalPixels > 0 else { return 0 }
        return Double(hotCount) / Double(totalPixels)
    }

    // MARK: - Calibrated Conversion

    /// Converts raw luminance (cd/m²) to sky brightness (mag/arcsec²).
    ///
    /// Formula: `y = a * log10(x) + b + c * temp_c`
    /// where x is rawLuminance, and a/b/c come from the calibration table.
    static func pixelLuminanceToMagArcsec2(
        rawLuminance: Double,
        calibration: CalibrationCoefficients,
        temperatureC: Double = 25.0
    ) -> Double {
        guard rawLuminance > 0 else {
            return SkyBrightnessConstants.urbanMinMagArcsec2
        }
        let logLuminance = log10(rawLuminance)
        return calibration.a * logLuminance + calibration.b + calibration.c * temperatureC
    }

    /// Maps sky brightness (mag/arcsec²) to Bortle class (1–9).
    ///
    /// Higher mag/arcsec² = darker sky = lower Bortle class.
    /// Iterates thresholds in descending order; first match wins.
    static func bortleClass(from skyBrightness: Double) -> Int {
        for threshold in SkyBrightnessConstants.bortleThresholds {
            if skyBrightness >= threshold.minMag {
                return threshold.bortleClass
            }
        }
        return 9
    }
}
