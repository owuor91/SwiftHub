//
//  RepositoryViewController.swift
//  SwiftHub
//
//  Created by Sygnoos9 on 7/1/18.
//  Copyright © 2018 Khoren Markosyan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import AttributedLib

private let reuseIdentifier = R.reuseIdentifier.repositoryDetailCell.identifier

class RepositoryViewController: TableViewController {

    var viewModel: RepositoryViewModel!

    lazy var rightBarButton: BarButtonItem = {
        let view = BarButtonItem(image: R.image.icon_navigation_github(), style: .done, target: nil, action: nil)
        return view
    }()

    lazy var ownerImageView: SlideImageView = {
        let view = SlideImageView()
        view.cornerRadius = 50
        return view
    }()

    lazy var starButton: Button = {
        let view = Button()
        view.borderColor = .white
        view.borderWidth = Configs.BaseDimensions.borderWidth
        view.tintColor = .white
        view.cornerRadius = 20
        view.hero.id = "ActionButtonId"
        return view
    }()

    lazy var detailLabel: Label = {
        var view = Label()
        view.numberOfLines = 0
        return view
    }()

    lazy var headerStackView: StackView = {
        let headerView = View()
        headerView.addSubview(self.ownerImageView)
        self.ownerImageView.snp.makeConstraints({ (make) in
            make.top.left.centerX.centerY.equalToSuperview()
            make.size.equalTo(100)
        })
        headerView.addSubview(self.starButton)
        self.starButton.snp.remakeConstraints({ (make) in
            make.bottom.equalTo(self.ownerImageView)
            make.right.equalTo(self.ownerImageView)
            make.size.equalTo(40)
        })
        let subviews: [UIView] = [headerView, self.detailLabel]
        let view = StackView(arrangedSubviews: subviews)
        view.axis = .horizontal
        return view
    }()

    lazy var headerView: View = {
        let view = View()
        view.hero.id = "TopHeaderId"
        let subviews: [UIView] = [self.headerStackView, self.actionButtonsStackView]
        let stackView = StackView(arrangedSubviews: subviews)
        view.addSubview(stackView)
        stackView.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview().inset(self.inset)
        })
        return view
    }()

    lazy var watchersButton: Button = {
        let view = Button()
        return view
    }()

    lazy var starsButton: Button = {
        let view = Button()
        return view
    }()

    lazy var forksButton: Button = {
        let view = Button()
        return view
    }()

    lazy var actionButtonsStackView: StackView = {
        let subviews: [UIView] = [self.watchersButton, self.starsButton, self.forksButton]
        let view = StackView(arrangedSubviews: subviews)
        view.axis = .horizontal
        view.distribution = .fillEqually
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func makeUI() {
        super.makeUI()

        themeService.rx
            .bind({ $0.primaryDark }, to: headerView.rx.backgroundColor)
            .bind({ $0.text }, to: detailLabel.rx.textColor)
            .disposed(by: rx.disposeBag)

        navigationItem.rightBarButtonItem = rightBarButton
        emptyDataSetTitle = ""
        emptyDataSetImage = nil
        stackView.insertArrangedSubview(headerView, at: 0)
        tableView.footRefreshControl = nil
        tableView.register(R.nib.repositoryDetailCell)
    }

    override func bindViewModel() {
        super.bindViewModel()

        let refresh = Observable.of(Observable.just(()), headerRefreshTrigger).merge()
        let input = RepositoryViewModel.Input(headerRefresh: refresh,
                                              imageSelection: ownerImageView.rx.tap(),
                                              openInWebSelection: rightBarButton.rx.tap.asObservable(),
                                              watchersSelection: watchersButton.rx.tap.asObservable(),
                                              starsSelection: starsButton.rx.tap.asObservable(),
                                              forksSelection: forksButton.rx.tap.asObservable(),
                                              selection: tableView.rx.modelSelected(RepositorySectionItem.self).asDriver(),
                                              starSelection: starButton.rx.tap.asObservable())
        let output = viewModel.transform(input: input)

        viewModel.loading.asObservable().bind(to: isLoading).disposed(by: rx.disposeBag)
        viewModel.headerLoading.asObservable().bind(to: isHeaderLoading).disposed(by: rx.disposeBag)

        let dataSource = RxTableViewSectionedReloadDataSource<RepositorySection>(configureCell: { dataSource, tableView, indexPath, item in
            switch item {
            case .languageItem(let viewModel),
                 .sizeItem(let viewModel),
                 .createdItem(let viewModel),
                 .updatedItem(let viewModel),
                 .homepageItem(let viewModel),
                 .issuesItem(let viewModel),
                 .commitsItem(let viewModel),
                 .pullRequestsItem(let viewModel),
                 .eventsItem(let viewModel),
                 .notificationsItem(let viewModel),
                 .contributorsItem(let viewModel),
                 .readmeItem(let viewModel),
                 .sourceItem(let viewModel),
                 .starHistoryItem(let viewModel):
                let cell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? RepositoryDetailCell)!
                cell.bind(to: viewModel)
                return cell
            }
        }, titleForHeaderInSection: { dataSource, index in
            let section = dataSource[index]
            return section.title
        })

        output.items
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)

        output.selectedEvent.drive(onNext: { [weak self] (item) in
            switch item {
            case .homepageItem:
                if let url = self?.viewModel.repository.value.homepage?.url {
                    self?.navigator.show(segue: .webController(url), sender: self)
                }
            case .issuesItem:
                if let viewModel = self?.viewModel.viewModel(for: item) as? IssuesViewModel {
                    self?.navigator.show(segue: .issues(viewModel: viewModel), sender: self)
                }
            case .commitsItem:
                if let viewModel = self?.viewModel.viewModel(for: item) as? CommitsViewModel {
                    self?.navigator.show(segue: .commits(viewModel: viewModel), sender: self)
                }
            case .pullRequestsItem:
                if let viewModel = self?.viewModel.viewModel(for: item) as? PullRequestsViewModel {
                    self?.navigator.show(segue: .pullRequests(viewModel: viewModel), sender: self)
                }
            case .eventsItem:
                if let viewModel = self?.viewModel.viewModel(for: item) as? EventsViewModel {
                    self?.navigator.show(segue: .events(viewModel: viewModel), sender: self)
                }
            case .notificationsItem:
                if let viewModel = self?.viewModel.viewModel(for: item) as? NotificationsViewModel {
                    self?.navigator.show(segue: .notifications(viewModel: viewModel), sender: self)
                }
            case .contributorsItem:
                if let viewModel = self?.viewModel.viewModel(for: item) as? UsersViewModel {
                    self?.navigator.show(segue: .users(viewModel: viewModel), sender: self)
                }
            case .readmeItem:
                if let url = self?.viewModel.readme.value?.htmlUrl?.url {
                    self?.navigator.show(segue: .webController(url), sender: self)
                    if let fullname = self?.viewModel.repository.value.fullname {
                        analytics.log(.readme(fullname: fullname))
                    }
                }
            case .sourceItem:
                if let viewModel = self?.viewModel.viewModel(for: item) as? ContentsViewModel {
                    self?.navigator.show(segue: .contents(viewModel: viewModel), sender: self)
                    if let fullname = viewModel.repository.value.fullname {
                        analytics.log(.source(fullname: fullname))
                    }
                }
            case .starHistoryItem:
                if let url = self?.viewModel.starHistoryUrl() {
                    self?.navigator.show(segue: .webController(url), sender: self)
                }
            default:
                self?.deselectSelectedRow()
            }
        }).disposed(by: rx.disposeBag)

        output.name.drive(onNext: { [weak self] (title) in
            self?.navigationTitle = title
        }).disposed(by: rx.disposeBag)

        output.description.drive(detailLabel.rx.text).disposed(by: rx.disposeBag)

        output.imageUrl.drive(onNext: { [weak self] (url) in
            if let url = url {
                self?.ownerImageView.setSources(sources: [url])
                self?.ownerImageView.hero.id = url.absoluteString
            }
        }).disposed(by: rx.disposeBag)

        output.hidesStarButton.drive(starButton.rx.isHidden).disposed(by: rx.disposeBag)

        output.starring.map { (starred) -> UIImage? in
            let image = starred ? R.image.icon_button_unstar() : R.image.icon_button_star()
            return image?.template
        }.drive(starButton.rx.image()).disposed(by: rx.disposeBag)

        output.watchersCount.drive(onNext: { [weak self] (count) in
            let text = R.string.localizable.repositoryWatchersButtonTitle.key.localized()
            self?.watchersButton.setAttributedTitle(self?.attributetText(title: text, value: count), for: .normal)
        }).disposed(by: rx.disposeBag)

        output.starsCount.drive(onNext: { [weak self] (count) in
            let text = R.string.localizable.repositoryStarsButtonTitle.key.localized()
            self?.starsButton.setAttributedTitle(self?.attributetText(title: text, value: count), for: .normal)
        }).disposed(by: rx.disposeBag)

        output.forksCount.drive(onNext: { [weak self] (count) in
            let text = R.string.localizable.repositoryForksButtonTitle.key.localized()
            self?.forksButton.setAttributedTitle(self?.attributetText(title: text, value: count), for: .normal)
        }).disposed(by: rx.disposeBag)

        output.imageSelected.drive(onNext: { [weak self] (viewModel) in
            self?.navigator.show(segue: .userDetails(viewModel: viewModel), sender: self)
        }).disposed(by: rx.disposeBag)

        output.openInWebSelected.drive(onNext: { [weak self] (url) in
            self?.navigator.show(segue: .webController(url), sender: self)
        }).disposed(by: rx.disposeBag)

        output.repositoriesSelected.drive(onNext: { [weak self] (viewModel) in
            self?.navigator.show(segue: .repositories(viewModel: viewModel), sender: self)
        }).disposed(by: rx.disposeBag)

        output.usersSelected.drive(onNext: { [weak self] (viewModel) in
            self?.navigator.show(segue: .users(viewModel: viewModel), sender: self)
        }).disposed(by: rx.disposeBag)
    }

    func attributetText(title: String, value: Int) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let valueAttributes = Attributes {
            return $0.foreground(color: .white)
                .font(.boldSystemFont(ofSize: 18))
                .paragraphStyle(paragraph)
        }

        let titleAttributes = Attributes {
            return $0.foreground(color: .white)
                .font(.boldSystemFont(ofSize: 12))
                .paragraphStyle(paragraph)
        }

        return "\(value)\n".at.attributed(with: valueAttributes) + title.at.attributed(with: titleAttributes)
    }
}
