import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    private let baseURL = "https://hbiwuhfgarke.ap-southeast-1.clawcloudrun.com"

    private init() {}

    func fetchHomework(completion: @escaping (Result<[Homework], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/homework")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
