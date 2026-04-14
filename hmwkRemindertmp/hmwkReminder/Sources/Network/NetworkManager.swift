import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    private let baseURL = "https://hbiwuhfgarke.ap-southeast-1.clawcloudrun.com"
    private let username = "admin"
    private let password = "admin"

    private init() {}

    private func makeRequest(path: String) -> URLRequest {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {
            request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func fetchHomework(completion: @escaping (Result<[Homework], Error>) -> Void) {
        let request = makeRequest(path: "/api/homework")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无数据"]))) }
                return
            }
            do {
                let response = try JSONDecoder().decode(HomeworkListResponse.self, from: data)
                DispatchQueue.main.async {
                    if response.code == 0, let homework = response.data {
                        completion(.success(homework))
                    } else {
                        completion(.failure(NSError(domain: "", code: response.code, userInfo: [NSLocalizedDescriptionKey: response.msg ?? "请求失败"])))
                    }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}
