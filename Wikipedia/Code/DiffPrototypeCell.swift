
import UIKit

class DiffPrototypeCell: UICollectionViewCell {
    @IBOutlet var textLabel: UILabel!
    private var widthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Addresses a separate issue and prevent auto layout warnings due to the temporary width constraint in the xib.
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Code below is needed to make the self-sizing cell work when building for iOS 12 from Xcode 10.0:
        let leftConstraint = contentView.leftAnchor.constraint(equalTo: leftAnchor)
        let rightConstraint = contentView.rightAnchor.constraint(equalTo: rightAnchor)
        let topConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([leftConstraint, rightConstraint, topConstraint, bottomConstraint])
        widthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
    }
    
    func configure(item: DiffItem, width: CGFloat) {
        widthConstraint.constant = width
        widthConstraint.isActive = true
        
        if item.type == .moveDestination || item.type == .moveSource {
            backgroundColor = .yellow
        } else {
            backgroundColor = .white
        }
        
        //todo: pass in single closure to both
        let insertedRanges: [NSRange] = item.highlightRanges.filter { $0.type == .add }.map {
            
            // Compute String.UnicodeScalarView indices for first and last position:
            let fromIdx = item.text.utf8.index(item.text.utf8.startIndex, offsetBy: $0.start)
            let toIdx = item.text.utf8.index(fromIdx, offsetBy: $0.length)
            
            // Compute corresponding NSRange:
            let nsRange = NSRange(fromIdx..<toIdx, in: item.text)
            
            return nsRange
        }
        let deletedRanges: [NSRange] = item.highlightRanges.filter { $0.type == .delete }.map {
            
            // Compute String.UnicodeScalarView indices for first and last position:
            let fromIdx = item.text.utf8.index(item.text.utf8.startIndex, offsetBy: $0.start)
            let toIdx = item.text.utf8.index(fromIdx, offsetBy: $0.length)
            
            // Compute corresponding NSRange:
            let nsRange = NSRange(fromIdx..<toIdx, in: item.text)
            
            return nsRange
        }
        
        setAttributedString(text: item.text, insertedRanges: insertedRanges, deletedRanges: deletedRanges)
    }
    
    private func setAttributedString(text: String, insertedRanges: [NSRange], deletedRanges: [NSRange]) {
        
        //let one = "\""
        //let two = "\\\""
        //let whytheHellNot = text.replacingOccurrences(of: one, with: two)
        let attributedString = NSMutableAttributedString(string: text)
        
        for insertedRange in insertedRanges {
            attributedString.setAttributes([NSAttributedString.Key.backgroundColor: UIColor.green], range: insertedRange)
        }
        
        for deletedRange in deletedRanges {
            attributedString.setAttributes([NSAttributedString.Key.backgroundColor: UIColor.red], range: deletedRange)
        }
        
        textLabel.attributedText = attributedString.copy() as? NSAttributedString
    }
}
