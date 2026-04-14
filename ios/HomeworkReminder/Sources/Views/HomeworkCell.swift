import UIKit
import SnapKit

class HomeworkCell: UITableViewCell {

    static let identifier = "HomeworkCell"

    private let cardView: GlassCardView = {
        let view = GlassCardView()
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let deadlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        return label
    }()

    private let remainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .right
        return label
    }()

    private let urgentIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange
        view.layer.cornerRadius = 4
        return view
    }()

    private let overdueIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed
        view.layer.cornerRadius = 4
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.addSubview(stackView)
        cardView.addSubview(remainingLabel)
        cardView.addSubview(urgentIndicator)
        cardView.addSubview(overdueIndicator)

        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(deadlineLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }

        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(remainingLabel.snp.leading).offset(-12)
        }

        remainingLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(80)
        }

        urgentIndicator.snp.makeConstraints { make in
            make.width.equalTo(8)
            make.height.equalTo(8)
            make.trailing.equalTo(nameLabel.snp.leading).offset(-8)
            make.top.equalTo(nameLabel.snp.top).offset(4)
        }

        overdueIndicator.snp.makeConstraints { make in
            make.width.equalTo(8)
            make.height.equalTo(8)
            make.trailing.equalTo(nameLabel.snp.leading).offset(-8)
            make.top.equalTo(nameLabel.snp.top).offset(4)
        }
    }

    func configure(with homework: Homework) {
        nameLabel.text = homework.name
        deadlineLabel.text = homework.deadline
        remainingLabel.text = homework.remainingTimeDescription

        urgentIndicator.isHidden = !homework.isUrgent
        overdueIndicator.isHidden = !homework.isOverdue

        if homework.isOverdue {
            remainingLabel.textColor = .systemRed
            nameLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        } else if homework.isUrgent {
            remainingLabel.textColor = .systemOrange
            nameLabel.textColor = .white
        } else {
            remainingLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            nameLabel.textColor = .white
        }
    }

    func animateCell() {
        cardView.animateIn(delay: 0)
    }
}
