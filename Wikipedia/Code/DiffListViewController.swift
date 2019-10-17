
import UIKit

protocol DiffListDelegate: class {
    func diffListScrollViewDidScroll(_ scrollView: UIScrollView)
}

class DiffListViewController: ColumnarCollectionViewController {

    var dataSource: [DiffListGroupViewModel] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    private weak var delegate: DiffListDelegate?
    
    init(theme: Theme, delegate: DiffListDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutManager.register(DiffListChangeCell.self, forCellWithReuseIdentifier: DiffListChangeCell.reuseIdentifier, addPlaceholder: true)
        layoutManager.register(DiffListContextCell.self, forCellWithReuseIdentifier: DiffListContextCell.reuseIdentifier, addPlaceholder: true)
        layoutManager.register(DiffListUneditedCell.self, forCellWithReuseIdentifier: DiffListUneditedCell.reuseIdentifier, addPlaceholder: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        delegate?.diffListScrollViewDidScroll(scrollView)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            //
        }) { _ in
            self.updateScrollViewInsets()
        }
        super.willTransition(to: newCollection, with: coordinator)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let viewModel = dataSource[safeIndex: indexPath.item] else {
            return UICollectionViewCell()
        }
        
        //tonitodo: clean up
        
        if let viewModel = viewModel as? DiffListChangeViewModel,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListChangeCell.reuseIdentifier, for: indexPath) as? DiffListChangeCell {
            configure(changeCell: cell, viewModel: viewModel)
            return cell
        } else if let viewModel = viewModel as? DiffListContextViewModel,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListContextCell.reuseIdentifier, for: indexPath) as? DiffListContextCell {
            configure(contextCell: cell, viewModel: viewModel, indexPath: indexPath)
            return cell
        } else if let viewModel = viewModel as? DiffListUneditedViewModel,
                   let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListUneditedCell.reuseIdentifier, for: indexPath) as? DiffListUneditedCell {
                   configure(uneditedCell: cell, viewModel: viewModel)
                   return cell
        }
        
        return UICollectionViewCell()
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 54)
        
        guard let viewModel = dataSource[safeIndex: indexPath.item] else {
            return estimate
        }
        
        if let viewModel = viewModel as? DiffListUneditedViewModel,
            let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: DiffListUneditedCell.reuseIdentifier) as? DiffListUneditedCell {
            configure(uneditedCell: placeholderCell, viewModel: viewModel)
            estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
            estimate.precalculated = true
        } else if let viewModel = viewModel as? DiffListChangeViewModel,
            let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: DiffListUneditedCell.reuseIdentifier) as? DiffListChangeCell {
            configure(changeCell: placeholderCell, viewModel: viewModel)
            estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
            estimate.precalculated = true
        } else if let viewModel = viewModel as? DiffListContextViewModel,
            let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: DiffListUneditedCell.reuseIdentifier) as? DiffListContextCell {
            configure(contextCell: placeholderCell, viewModel: viewModel, indexPath: indexPath)
            estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
            estimate.precalculated = true
        }
        
        return estimate
    }
    
    private func configure(uneditedCell: DiffListUneditedCell, viewModel: DiffListUneditedViewModel) {
        uneditedCell.update(viewModel)
        uneditedCell.layoutMargins = layout.itemLayoutMargins
        uneditedCell.apply(theme: theme)
    }
    
    private func configure(changeCell: DiffListChangeCell, viewModel: DiffListChangeViewModel) {
        changeCell.update(viewModel)
        changeCell.layoutMargins = layout.itemLayoutMargins
        changeCell.apply(theme: theme)
    }
    
    private func configure(contextCell: DiffListContextCell, viewModel: DiffListContextViewModel, indexPath: IndexPath) {
        contextCell.update(viewModel, indexPath: indexPath)
        contextCell.layoutMargins = layout.itemLayoutMargins
        contextCell.apply(theme: theme)
        contextCell.delegate = self
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins)
    }
    
    override func apply(theme: Theme) {
        
        guard isViewLoaded else {
            return
        }
        
        super.apply(theme: theme)

        collectionView.backgroundColor = theme.colors.paperBackground
    }
}

extension DiffListViewController: DiffListContextCellDelegate {
    func didTapContextExpand(indexPath: IndexPath, viewModel: DiffListContextViewModel, cell: DiffListContextCell) {

        viewModel.isExpanded.toggle()
        cell.update(viewModel, indexPath: indexPath)
        if let layoutCopy = layout.copy() as? ColumnarCollectionViewLayout {
            collectionView.setCollectionViewLayout(layoutCopy, animated: true)
        }
    }
}
