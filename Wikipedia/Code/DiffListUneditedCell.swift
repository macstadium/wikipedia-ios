
import UIKit

class DiffListUneditedCell: CollectionViewCell {
    
    static let reuseIdentifier = "DiffListUneditedCell"

    let textLabel: UILabel = UILabel()
    let divView: UIView = UIView()
    let textBackgroundView = UIView()
    private var viewModel: DiffListUneditedViewModel?
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left, bottom: 0, right: layoutMargins.right)
        
        let textX = adjustedMargins.left
        let textMaxX = size.width - adjustedMargins.right - adjustedMargins.left
        let textOrigin = CGPoint(x: textX, y: adjustedMargins.top)
        
        let textFrame = textLabel.wmf_preferredFrame(at: textOrigin, maximumWidth: textMaxX, alignedBy: .forceLeftToRight, apply: false)
        let finalHeight = adjustedMargins.top + textFrame.size.height + adjustedMargins.bottom
        
        if apply {
            divView.frame = CGRect(x: adjustedMargins.left, y: (textFrame.height / 2) + adjustedMargins.top, width: size.width - adjustedMargins.right, height: 1)
            textLabel.frame = CGRect(x: (size.width / 2) - (textFrame.width / 2), y: textFrame.minY, width: textFrame.width * 1.2, height: textFrame.height)
        }
        
        return CGSize(width: size.width, height: finalHeight)
        
    }
    
    override func setup() {
        super.setup()
        contentView.addSubview(divView)
        contentView.addSubview(textLabel)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
    }
    
    func update(_ viewModel: DiffListUneditedViewModel) {
        self.viewModel = viewModel
        
        textLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        textLabel.text = viewModel.text
    }
}

extension DiffListUneditedCell: Themeable {
    func apply(theme: Theme) {
        textLabel.textColor = theme.colors.secondaryText
        textLabel.backgroundColor = theme.colors.paperBackground
        backgroundColor = theme.colors.paperBackground
        textBackgroundView.backgroundColor = theme.colors.paperBackground
        divView.backgroundColor = theme.colors.border
    }
}
