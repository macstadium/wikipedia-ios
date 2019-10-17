
import UIKit

protocol DiffListContextCellDelegate: class {
    func didTapContextExpand(indexPath: IndexPath, viewModel: DiffListContextViewModel, cell: DiffListContextCell)
}

class DiffListContextCell: CollectionViewCell {
    static let reuseIdentifier = "DiffListContextCell"
    
    private var headingLabel = UILabel()
    private var expandButton = UIButton(type: .system)
    
    private var viewModel: DiffListContextViewModel?
    private var indexPath: IndexPath?
    private var contextViews: [UIView] = []
    
    weak var delegate: DiffListContextCellDelegate?
    
    let containerSpacing: CGFloat = 15
    let contextItemSpacing: CGFloat = 5
    let emptyContextHeightMultiplier: CGFloat = 1.8
    let contextItemTextPadding = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    
    override func setup() {
        super.setup()
        contentView.addSubview(headingLabel)
        contentView.addSubview(expandButton)
        headingLabel.numberOfLines = 1
        expandButton.addTarget(self, action: #selector(tappedExpandButton(_:)), for: .touchUpInside)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        removeContextViews()
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        guard let viewModel = viewModel else {
            return .zero
        }
        
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left, bottom: 0, right: layoutMargins.right)
        let headingY = adjustedMargins.top
        let headingX = adjustedMargins.left
        
        let buttonFrame = expandButton.wmf_preferredFrame(at: CGPoint(x: 0, y: 0), maximumWidth: size.width, alignedBy: .forceLeftToRight, apply: false)
        let buttonX = size.width - adjustedMargins.right - buttonFrame.width
        let headingMaxWidth = size.width - adjustedMargins.left - adjustedMargins.right - buttonFrame.width
        let headingFrame = headingLabel.wmf_preferredFrame(at: CGPoint(x: headingX, y: headingY), maximumWidth: headingMaxWidth, alignedBy: .forceLeftToRight, apply: apply)
        let buttonY = headingFrame.maxY - (headingFrame.height/2) //todo - baselines would be better than vertical center alignment
        
        var currentY = headingFrame.maxY + containerSpacing
        
        if !viewModel.isExpanded {
            
            if apply {
                expandButton.frame = CGRect(x: buttonX, y: buttonY, width: buttonFrame.width, height: buttonFrame.height)
            }
            
            return CGSize(width: size.width, height: currentY)
        }
        
        for (index, view) in contextViews.enumerated() {
            
            guard let contextItemViewModel = viewModel.items[safeIndex: index] else {
                continue
            }
            
            let labelMaxWidth = size.width - adjustedMargins.left - adjustedMargins.right - contextItemTextPadding.leading - contextItemTextPadding.trailing
            
            let contextViewWidth = size.width - adjustedMargins.left - adjustedMargins.right
            if let _ = contextItemViewModel {
                for subview in view.subviews {
                    if let labelSubview = subview as? UILabel {
                        let labelFrame = labelSubview.wmf_preferredFrame(at: CGPoint(x: contextItemTextPadding.leading, y: contextItemTextPadding.top), maximumWidth: labelMaxWidth, alignedBy: .forceLeftToRight, apply: apply)
                        
                        let viewFrame = CGRect(x: adjustedMargins.left, y: currentY, width: contextViewWidth, height: labelFrame.height + contextItemTextPadding.top + contextItemTextPadding.bottom)
                        if apply {
                            view.frame = viewFrame
                        }
                        
                        currentY += viewFrame.height
                        break
                    }
                }
            } else { //empty line
                
                let viewFrame = CGRect(x: adjustedMargins.left, y: currentY, width: contextViewWidth, height: viewModel.contextFont.pointSize * emptyContextHeightMultiplier)

                if apply {
                    view.frame = viewFrame
                }
                
                currentY += viewFrame.height
            }
            
            currentY += contextItemSpacing
        }
        
        if apply {
            expandButton.frame = CGRect(x: buttonX, y: buttonY, width: buttonFrame.width, height: buttonFrame.height)
        }
        
        return CGSize(width: size.width, height: currentY)
    }
    
    func update(_ viewModel: DiffListContextViewModel, indexPath: IndexPath?) {
        
        self.viewModel = viewModel
        
        if let indexPath = indexPath {
            self.indexPath = indexPath
        }
        
        addContextViews(newViewModel: viewModel)
        
        headingLabel.font = viewModel.headingFont
        headingLabel.text = viewModel.heading
        expandButton.setTitle(viewModel.expandButtonTitle, for: .normal)
        expandButton.titleLabel?.font = viewModel.contextFont
        
        apply(theme: viewModel.theme)

        updateContextViews(newViewModel: viewModel, theme: viewModel.theme)
    }
    
    @IBAction func tappedExpandButton(_ sender: UIButton) {
        if let indexPath = indexPath,
            let viewModel = viewModel {
            delegate?.didTapContextExpand(indexPath: indexPath, viewModel: viewModel, cell: self)
        }
    }
}

private extension DiffListContextCell {
    
    func removeContextViews() {
        for subview in contextViews {
            subview.removeFromSuperview()
        }
    }
    
    func addContextViews(newViewModel: DiffListContextViewModel) {
        
        guard contextViews.isEmpty else {
            return
        }
        
        for item in newViewModel.items {
            
            if item != nil {
                
                //needs label
                let label = UILabel()
                label.numberOfLines = 0
                label.lineBreakMode = .byWordWrapping
                label.translatesAutoresizingMaskIntoConstraints = false
                
                let view = UIView(frame: .zero)
                view.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(label)
                contentView.addSubview(view)
                contextViews.append(view)

            } else {
                let view = UIView(frame: .zero)
                contentView.addSubview(view)
                contextViews.append(view)
            }
        }
    }
    
    func updateContextViews(newViewModel: DiffListContextViewModel, theme: Theme) {
        for (index, subview) in contextViews.enumerated() {
            
            subview.backgroundColor = theme.colors.diffContextItemBackground
            subview.borderColor = theme.colors.diffContextItemBorder
            subview.borderWidth = 1
            subview.layer.cornerRadius = 5
            
            if let item = newViewModel.items[safeIndex: index] as? String,
            let label = subview.subviews.first as? UILabel {
                label.text = item
                label.font = newViewModel.contextFont
            }
        }
    }
}

extension DiffListContextCell: Themeable {
    func apply(theme: Theme) {
        headingLabel.textColor = theme.colors.secondaryText
        expandButton.tintColor = theme.colors.link
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        
        if let viewModel = viewModel {
            updateContextViews(newViewModel: viewModel, theme: theme)
        }
    }
}
