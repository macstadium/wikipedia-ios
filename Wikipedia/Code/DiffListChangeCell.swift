
import UIKit

class DiffListChangeCell: CollectionViewCell {
    static let reuseIdentifier = "DiffListChangeCell"
    
    let headingContainerView = UIView()
    let headingLabel = UILabel()
    var labels: [UILabel] = []
    let innerView = UIView()
    
    private var theme: Theme?
    private(set) var viewModel: DiffListChangeViewModel?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        removeTextLabels()
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        guard let viewModel = viewModel else {
            return .zero
        }
        
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left, bottom: 0, right: layoutMargins.right)
        let textPadding = self.textPadding(for: viewModel)
        let headingPadding = self.headingPadding(for: viewModel)
        
        let innerViewWidth = size.width - adjustedMargins.left - adjustedMargins.right
        let textMaxWidth = innerViewWidth - textPadding.leading - textPadding.trailing
        let headingMaxWidth = innerViewWidth - headingPadding.leading - headingPadding.trailing
        
        let headingY = adjustedMargins.top + headingPadding.top
        let headingX = adjustedMargins.left + headingPadding.leading
        let headingOrigin = CGPoint(x: headingX, y: headingY)
        let headingFrame = headingLabel.wmf_preferredFrame(at: headingOrigin, maximumWidth: headingMaxWidth, alignedBy: .forceLeftToRight, apply: apply)
        
        var currentY = headingFrame.maxY + headingPadding.bottom
        let originX = adjustedMargins.left + textPadding.leading
        var innerViewHeight: CGFloat = headingPadding.top + headingFrame.height + headingPadding.bottom
        
        for label in labels {
            currentY += textPadding.top
            innerViewHeight += textPadding.top
            let labelOrigin = CGPoint(x: originX, y: currentY)
            let labelFrame = label.wmf_preferredFrame(at: labelOrigin, maximumWidth: textMaxWidth, alignedBy: .forceLeftToRight, apply: apply)
            currentY += labelFrame.height
            innerViewHeight += labelFrame.height
            currentY += textPadding.bottom
            innerViewHeight += textPadding.bottom
        }
        
        if apply {
            innerView.frame = CGRect(x: adjustedMargins.left, y: adjustedMargins.top, width: innerViewWidth, height: innerViewHeight)
            headingContainerView.frame = CGRect(x: 0, y: 0, width: innerViewWidth, height: headingFrame.height + headingPadding.top + headingPadding.bottom)
        }
        
        let finalHeight = currentY + adjustedMargins.bottom
        
        return CGSize(width: size.width, height: finalHeight)
        
    }
    
    private func textPadding(for viewModel: DiffListChangeViewModel) -> NSDirectionalEdgeInsets {
        switch viewModel.type {
        case .compareRevision:
            return NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        case .singleRevison:
            return NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
    }
    
    private func headingPadding(for viewModel: DiffListChangeViewModel) -> NSDirectionalEdgeInsets {
        switch viewModel.type {
        case .compareRevision:
            return NSDirectionalEdgeInsets(top: 10, leading: 7, bottom: 10, trailing: 7)
        case .singleRevison:
            return NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 10, trailing: 0)
        }
    }
    
    func update(_ viewModel: DiffListChangeViewModel) {
        
        self.viewModel = viewModel

        addTextLabels(newViewModel: viewModel)
        headingLabel.text = viewModel.heading
        headingLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        apply(theme: viewModel.theme)
        updateTextLabels(newViewModel: viewModel)
    }
    
    override func setup() {
        super.setup()
        contentView.addSubview(innerView)
        innerView.addSubview(headingContainerView)
        contentView.addSubview(headingLabel)
        headingLabel.numberOfLines = 0
        innerView.borderWidth = 1
    }
}

private extension DiffListChangeCell {
    func removeTextLabels() {

        for label in labels {
            label.removeFromSuperview()
        }
        
        labels.removeAll()
    }
    
    func addTextLabels(newViewModel: DiffListChangeViewModel) {
        
        guard labels.isEmpty else {
            return
        }
        
        for _ in newViewModel.items {
            let label = UILabel()
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            contentView.addSubview(label)
            labels.append(label)
        }
    }
    
    func updateTextLabels(newViewModel: DiffListChangeViewModel) {
        for (index, label) in labels.enumerated() {
            if let item = newViewModel.items[safeIndex: index],
                let theme = theme {
                label.attributedText = calculateAttributedString(with: item, traitCollection: traitCollection, theme: theme)
            }
        }
    }
    
    func calculateAttributedString(with viewModel: DiffListChangeItemViewModel, traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
            
        let regularFontStyle: DynamicTextStyle = viewModel.type == .singleRevison ? .callout : .footnote
        let boldFontStyle: DynamicTextStyle = viewModel.type == .singleRevison ? .boldCallout : .boldFootnote
            
        let font = UIFont.wmf_font(regularFontStyle, compatibleWithTraitCollection: traitCollection)
//        let paragraphStyle = NSMutableParagraphStyle()
//        let lineSpacing: CGFloat = 4
//        paragraphStyle.lineSpacing = lineSpacing
//        paragraphStyle.lineHeightMultiple = font.lineHeightMultipleToMatch(lineSpacing: lineSpacing)
        let attributes = [NSAttributedString.Key.font: font]
                          //NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let attributedString = NSAttributedString(string: viewModel.text, attributes: attributes)
            
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            
            for range in viewModel.highlightedRanges {
                
                let nsRange = NSRange(location: range.start, length: range.length)
                let highlightColor: UIColor
                
                switch range.type {
                case .added:
                    highlightColor = theme.colors.diffHighlightAdd
                    
                case .deleted:
                    highlightColor = theme.colors.diffHighlightDelete
                    let deletedAttributes: [NSAttributedString.Key: Any]  = [
                        NSAttributedString.Key.strikethroughStyle:NSUnderlineStyle.single.rawValue,
                        NSAttributedString.Key.strikethroughColor:UIColor.black
                    ]
                    mutableAttributedString.addAttributes(deletedAttributes, range: nsRange)
                }
                
                mutableAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: highlightColor, range: nsRange)
                mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.wmf_font(boldFontStyle, compatibleWithTraitCollection: traitCollection), range: nsRange)
            }
            
            return mutableAttributedString
        }
}

extension DiffListChangeCell: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        
        for label in labels {
            label.textColor = theme.colors.primaryText
        }
        
        if let viewModel = viewModel {
            innerView.borderColor = viewModel.borderColor
            innerView.layer.cornerRadius = viewModel.cornerRadius
            innerView.clipsToBounds = viewModel.cornerRadius > 0
            headingContainerView.backgroundColor = viewModel.borderColor
            
            switch viewModel.type {
            case .compareRevision:
                headingLabel.textColor = UIColor.white //tonitodo: should this change based on theme
            case .singleRevison:
                headingLabel.textColor = theme.colors.secondaryText
            }
        }
        
        if let viewModel = viewModel {
            updateTextLabels(newViewModel: viewModel)
        }
    }
}
