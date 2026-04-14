import UIKit
import SnapKit

class HomeViewController: UIViewController {

    private var homeworks: [Homework] = []

    private let backgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1).cgColor,
            UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1).cgColor,
            UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1).cgColor
        ]
        layer.locations = [0, 0.5, 1]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()

    private let blurEffect: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemThickMaterialDark)
        let view = UIVisualEffectView(effect: blur)
        return view
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        table.register(HomeworkCell.self, forCellReuseIdentifier: HomeworkCell.identifier)
        table.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        table.showsVerticalScrollIndicator = false
        return table
    }()

    private let refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.tintColor = .white
        return refresh
    }()

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "作业提醒"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        return label
    }()

    private let emptyView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无作业"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.textAlignment = .center
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        fetchData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupUI() {
        view.layer.insertSublayer(backgroundGradient, at: 0)

        view.addSubview(blurEffect)
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        view.addSubview(tableView)
        view.addSubview(emptyView)
        emptyView.addSubview(emptyLabel)
        view.addSubview(loadingIndicator)

        blurEffect.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(80)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(20)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(100)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)

        updateSubtitle()
    }

    private func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    @objc private func refreshData() {
        fetchData()
    }

    private func fetchData() {
        if homeworks.isEmpty {
            loadingIndicator.startAnimating()
        }

        NetworkManager.shared.fetchHomework { [weak self] result in
            guard let self = self else { return }

            self.loadingIndicator.stopAnimating()
            self.refreshControl.endRefreshing()

            switch result {
            case .success(let data):
                self.homeworks = self.sortHomeworks(data)
                self.tableView.reloadData()
                self.emptyView.isHidden = !data.isEmpty
                self.updateSubtitle()
                self.animateTableViewCells()

            case .failure(let error):
                self.showError(error.localizedDescription)
            }
        }
    }

    private func sortHomeworks(_ homeworks: [Homework]) -> [Homework] {
        return homeworks.sorted { hw1, hw2 in
            guard let date1 = hw1.deadlineDate, let date2 = hw2.deadlineDate else {
                return hw1.deadline < hw2.deadline
            }
            return date1 < date2
        }
    }

    private func updateSubtitle() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 HH:mm"
        subtitleLabel.text = formatter.string(from: now)

        let urgentCount = homeworks.filter { $0.isUrgent && !$0.isOverdue }.count
        if urgentCount > 0 {
            subtitleLabel.text = "\(formatter.string(from: now)) · \(urgentCount) 项紧急"
        }
    }

    private func animateTableViewCells() {
        for (index, cell) in tableView.visibleCells.enumerated() {
            if let homeworkCell = cell as? HomeworkCell {
                UIView.animate(withDuration: 0.3, delay: Double(index) * 0.05, options: .curveEaseOut) {
                    homeworkCell.alpha = 1
                    homeworkCell.transform = .identity
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return homeworks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeworkCell.identifier, for: indexPath) as? HomeworkCell else {
            return UITableViewCell()
        }

        let homework = homeworks[indexPath.row]
        cell.configure(with: homework)
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 20)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let homeworkCell = cell as? HomeworkCell {
            homeworkCell.animateCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? HomeworkCell {
            cell.animatePulse()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y

        if offsetY < 0 {
            let scale = 1 + abs(offsetY) / 500
            backgroundGradient.transform = CATransform3DMakeScale(scale, scale, 1)
        } else {
            backgroundGradient.transform = CATransform3DIdentity
        }
    }
}
