import CoreVideo
import XCTest
@testable import Nocturne

final class MeasurementEnginePixelTests: XCTestCase {

    // MARK: - Average Luminance

    func testAverageLuminance_uniformBuffer128() {
        let buffer = makePixelBuffer(width: 480, height: 480, fillR: 128, fillG: 128, fillB: 128)
        let result = MeasurementEngine.averageLuminance(from: buffer)
        // normalized = 128/255 ≈ 0.502; luma = 0.502^2.2 * 80 ≈ 18.5
        XCTAssertGreaterThan(result, 15.0)
        XCTAssertLessThan(result, 25.0)
    }

    func testAverageLuminance_blackBuffer() {
        let buffer = makePixelBuffer(width: 480, height: 480, fillR: 0, fillG: 0, fillB: 0)
        let result = MeasurementEngine.averageLuminance(from: buffer)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    func testAverageLuminance_whiteBuffer() {
        let buffer = makePixelBuffer(width: 480, height: 480, fillR: 255, fillG: 255, fillB: 255)
        let result = MeasurementEngine.averageLuminance(from: buffer)
        // 1.0^2.2 * 80 = 80.0
        XCTAssertEqual(result, 80.0, accuracy: 1.0)
    }

    func testAverageLuminance_onlySamplesCenterCrop() {
        // Create buffer where center 240×240 is black, surrounding is white
        let width = 480
        let height = 480
        let buffer = makePixelBuffer(width: width, height: height, fillR: 255, fillG: 255, fillB: 255)

        // Overwrite center crop with black
        CVPixelBufferLockBaseAddress(buffer, [])
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let ptr = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)

        let cropSize = 240
        let startX = (width - cropSize) / 2
        let startY = (height - cropSize) / 2

        for y in startY..<(startY + cropSize) {
            for x in startX..<(startX + cropSize) {
                let offset = y * bytesPerRow + x * 4
                ptr[offset] = 0     // B
                ptr[offset + 1] = 0 // G
                ptr[offset + 2] = 0 // R
                ptr[offset + 3] = 255
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        let result = MeasurementEngine.averageLuminance(from: buffer)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    // MARK: - Hot Pixel Fraction

    func testHotPixelFraction_allWhite() {
        let buffer = makePixelBuffer(width: 100, height: 100, fillR: 255, fillG: 255, fillB: 255)
        let result = MeasurementEngine.hotPixelFraction(in: buffer)
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func testHotPixelFraction_allBlack() {
        let buffer = makePixelBuffer(width: 100, height: 100, fillR: 0, fillG: 0, fillB: 0)
        let result = MeasurementEngine.hotPixelFraction(in: buffer)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    func testHotPixelFraction_halfWhite() {
        let width = 100
        let height = 100
        let buffer = makePixelBuffer(width: width, height: height, fillR: 0, fillG: 0, fillB: 0)

        // Make top half white
        CVPixelBufferLockBaseAddress(buffer, [])
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let ptr = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)

        for y in 0..<(height / 2) {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                ptr[offset] = 255     // B
                ptr[offset + 1] = 255 // G
                ptr[offset + 2] = 255 // R
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        let result = MeasurementEngine.hotPixelFraction(in: buffer)
        XCTAssertEqual(result, 0.5, accuracy: 0.01)
    }

    func testHotPixelFraction_singleBrightPixel() {
        let width = 100
        let height = 100
        let buffer = makePixelBuffer(width: width, height: height, fillR: 0, fillG: 0, fillB: 0)

        // Set one pixel to white
        CVPixelBufferLockBaseAddress(buffer, [])
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let ptr = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
        let offset = 50 * bytesPerRow + 50 * 4
        ptr[offset] = 255
        ptr[offset + 1] = 255
        ptr[offset + 2] = 255
        CVPixelBufferUnlockBaseAddress(buffer, [])

        let result = MeasurementEngine.hotPixelFraction(in: buffer)
        let expected = 1.0 / Double(width * height)
        XCTAssertEqual(result, expected, accuracy: 0.0001)
    }

    // MARK: - Helper

    private func makePixelBuffer(
        width: Int,
        height: Int,
        fillR: UInt8,
        fillG: UInt8,
        fillB: UInt8
    ) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            nil,
            &pixelBuffer
        )
        precondition(status == kCVReturnSuccess, "Failed to create pixel buffer")

        let buffer = pixelBuffer!
        CVPixelBufferLockBaseAddress(buffer, [])
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let ptr = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                ptr[offset] = fillB       // B
                ptr[offset + 1] = fillG   // G
                ptr[offset + 2] = fillR   // R
                ptr[offset + 3] = 255     // A
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }
}
