//
//  NetworkService.swift
//  SelectiVR
//
//  Created by byeoungjik on 7/18/25.
//  Copyright © 2025 Apple. All rights reserved.
//

import Foundation

// MARK: - Network Error Enum
// 네트워크 통신 과정에서 발생할 수 있는 에러를 구체적으로 정의합니다.
enum NetworkError: Error {
    case badURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(statusCode: Int, message: String? = nil) // 서버에서 내려주는 에러 메시지도 담을 수 있습니다.
    case decodingError(Error)
    case noData
    case unknown(Error? = nil)
}

// MARK: - Codable Structs for Type Safety
// 서버와 주고받는 JSON 데이터 형식을 Struct로 정의하여 타입 안정성을 확보합니다.

// Google 로그인 요청 본문
struct GoogleLoginRequest: Codable {
    let id_token: String
}

// 로그인 성공 응답
struct LoginResponse: Codable {
    let access_token: String
}

// 파일 업로드 성공/실패 응답
struct UploadResponse: Codable {
    let message: String
}

// 서버와의 모든 네트워크 통신을 담당하는 싱글톤 클래스입니다.
class NetworkService {
    
    static let shared = NetworkService()
    // baseURL은 환경에 따라 바뀔 수 있으므로 별도의 설정 파일로 관리하는 것이 더 좋습니다.
    private let baseURL = "https://selectivr.onrender.com"

    private init() {}

    // MARK: - 1. Google 로그인 정보 서버에 전송
    func loginWithGoogle(idToken: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/auth/google-login") else {
            throw NetworkError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // [개선] Codable Struct를 사용하여 요청 본문을 생성합니다.
        let requestBody = GoogleLoginRequest(id_token: idToken)
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw NetworkError.decodingError(error)
        }

        let (data, response) = try await performRequest(request)
        
        // [개선] Codable Struct를 사용하여 응답을 디코딩합니다.
        do {
            let result = try JSONDecoder().decode(LoginResponse.self, from: data)
            return result.access_token
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    // MARK: - 2. 인증된 사용자의 파일 업로드 (개선된 버전)
    func uploadModel(fileURL: URL, token: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/upload") else {
            throw NetworkError.badURL
        }
        
        // [개선] multipart/form-data 생성 로직을 헬퍼 함수로 분리하여 가독성과 안정성을 높입니다.
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let requestData: Data
        do {
            let fileData = try Data(contentsOf: fileURL)
            // [개선] 헬퍼 함수를 사용하여 multipart body를 생성합니다.
            requestData = createMultipartBody(boundary: boundary, fileData: fileData, fileName: fileURL.lastPathComponent)
        } catch {
            throw NetworkError.requestFailed(error)
        }

        let (data, response) = try await performRequest(request, uploadData: requestData)
        
        do {
            let result = try JSONDecoder().decode(UploadResponse.self, from: data)
            return result.message
        } catch {
            // [개선] 서버에서 에러 메시지를 보냈을 경우, 해당 메시지를 파싱하여 에러에 담아줍니다.
            let errorResponse = try? JSONDecoder().decode(UploadResponse.self, from: data)
            throw NetworkError.decodingError(error)
        }
    }
    
    // MARK: - Private Helper Functions

    /// 공통 요청 수행 및 응답 검증 로직
    private func performRequest(_ request: URLRequest, uploadData: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        let (data, response): (Data, URLResponse)
        
        do {
            if let uploadData = uploadData {
                (data, response) = try await URLSession.shared.upload(for: request, from: uploadData)
            } else {
                (data, response) = try await URLSession.shared.data(for: request)
            }
        } catch {
            throw NetworkError.requestFailed(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // [개선] 2xx 성공 코드가 아닌 경우, 구체적인 에러를 던집니다.
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        return (data, httpResponse)
    }
    
    /// Multipart/form-data 요청 본문을 생성하는 헬퍼 함수
    private func createMultipartBody(boundary: String, fileData: Data, fileName: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        
        // 파일 파트
        body.append("--\(boundary)\(lineBreak)")
        // 서버의 Flask 코드에서 `request.files['file']`로 접근하기 위해 name을 "file"로 설정합니다.
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(lineBreak)")
        // .usdz 파일의 공식 MIME 타입은 'model/vnd.usdz+zip' 이지만, 'application/octet-stream'도 일반적으로 사용됩니다.
        body.append("Content-Type: application/octet-stream\(lineBreak)\(lineBreak)")
        body.append(fileData)
        body.append(lineBreak)
        
        // 마지막 경계
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
}

// Data 확장을 통해 append(String)을 더 쉽게 사용하도록 만듭니다.
fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
