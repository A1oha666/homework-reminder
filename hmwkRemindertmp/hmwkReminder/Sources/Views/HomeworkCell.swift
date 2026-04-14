import UIKit

class HomeworkCell: UITableViewCell {

    static let identifier = "HomeworkCell"

    private let cardView = GlassCardView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let deadlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let remainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
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
        cardView.addSubview(indicatorView)

        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(deadlineLabel)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            stackView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            stackView.trailingAnchor.constraint(equalTo:remainingLabel.leadingAnchor, constant: -12),

            remainingLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            remainingLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            remainingLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            indicatorView.widthAnchor.constraint(equalToConstant: 8),
            indicatorView.heightAnchor.constraint(equalToConstant: 8),
            indicatorView.trailingAnchor.constraint(equalTo: nameLabel.leadingAnchor, constant: -8),
            indicatorView.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: 4)
        ])
    }

    func configure(with homework: Homework) {
        nameLabel.text = homework.name
        deadlineLabel.text = homework.deadline
        remainingLabel.text = homework.remainingTimeDescription

        if homework.isOverdue {
            remainingLabel.textColor = .systemRed
            nameLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            indicatorView.backgroundColor = .systemRed
            indicatorView.isHidden = false
        } else if homework.isUrgent {
            remainingLabel.textColor = .systemOrange
            nameLabel.textColor = .white
            indicatorView.backgroundColor = .systemOrange
            indicatorView.isHidden = false
        } else {
            remainingLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            nameLabel.textColor = .white
            indicatorView.isHidden = true
        }
    }

    func animateCell() {
        cardView.animateIn()
    }

    func animatePulse() {
        cardView.animatePulse()
    }
}
