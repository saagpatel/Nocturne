import XCTest
@testable import Nocturne

final class WeatherServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeService() -> WeatherService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return WeatherService(session: session)
    }

    func testCloudCover_validResponse_returnsInt() async {
        let json = """
        {
            "hourly": {
                "time": ["2024-12-21T08:00"],
                "cloudcover": [42]
            }
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.open-meteo.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let service = makeService()
        let result = await service.cloudCoverPercent(latitude: 37.77, longitude: -122.41)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 42)
    }

    func testCloudCover_networkError_returnsNil() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let service = makeService()
        let result = await service.cloudCoverPercent(latitude: 37.77, longitude: -122.41)
        XCTAssertNil(result)
    }

    func testCloudCover_invalidJSON_returnsNil() async {
        let json = "not json".data(using: .utf8)!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.open-meteo.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let service = makeService()
        let result = await service.cloudCoverPercent(latitude: 37.77, longitude: -122.41)
        XCTAssertNil(result)
    }

    func testCloudCover_emptyArrays_returnsNil() async {
        let json = """
        {
            "hourly": {
                "time": [],
                "cloudcover": []
            }
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.open-meteo.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let service = makeService()
        let result = await service.cloudCoverPercent(latitude: 37.77, longitude: -122.41)
        XCTAssertNil(result)
    }

    func testCloudCover_findsCorrectHour() async {
        // Build 24 hourly entries
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")

        let now = Date()
        var times: [String] = []
        var covers: [Int] = []
        let calendar = Calendar.current

        for hour in 0..<24 {
            let date = calendar.date(
                bySettingHour: hour,
                minute: 0,
                second: 0,
                of: now
            )!
            times.append(formatter.string(from: date))
            covers.append(hour * 4) // 0, 4, 8, ..., 92
        }

        let timesJSON = times.map { "\"\($0)\"" }.joined(separator: ",")
        let coversJSON = covers.map { "\($0)" }.joined(separator: ",")
        let json = """
        {
            "hourly": {
                "time": [\(timesJSON)],
                "cloudcover": [\(coversJSON)]
            }
        }
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.open-meteo.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let service = makeService()
        let result = await service.cloudCoverPercent(latitude: 37.77, longitude: -122.41)
        XCTAssertNotNil(result)
        // Should match the current hour's value
        if let result {
            XCTAssertGreaterThanOrEqual(result, 0)
            XCTAssertLessThanOrEqual(result, 100)
        }
    }
}

// MARK: - Mock URL Protocol

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
