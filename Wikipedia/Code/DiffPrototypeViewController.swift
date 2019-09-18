

import UIKit

class DiffPrototypeViewController: UIViewController {

    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var collectionView: UICollectionView!
    private let cellReuseIdentifier = "itemCell"
    private let sectionHeaderReuseIdentifier = "sectionHeaderView"
    private var dataSource: [DiffItem]?
    private let fetcher = DiffFetcher()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        flowLayout.estimatedItemSize = CGSize(width: 325, height: 100)
        flowLayout.itemSize = UICollectionViewFlowLayout.automaticSize
        populateDataSource()
    }
    
    @IBAction func tappedClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    private func populateDataSource() {
        
        guard let url = NSURL.wmf_URL(withDefaultSiteAndlanguage: "test") else {
            return
        }
        
//        fetcher.fetchDiffData(siteURL: url, fromRevisionID: 375751, toRevisionID: 399929) { (result) in
//            switch result {
//            case .success(let response):
                let diffBridge = WMFDiffBridge()
                let string1 = """
This is a paragraph. I hope we can reproduce moved lines. Let's try with this.
"""
                let string2 = """
Let's try with this. I hope we can reproduce moved lines. This is a paragraph. 
"""
                if let diff = diffBridge.diffResults(fromString1: string1, andString2: string2),
                    let data = diff.data(using: String.Encoding.utf8) {
                    do {
                            let response = try JSONDecoder().decode(DiffResponse.self, from: data)
                        DispatchQueue.main.async {
                            self.dataSource = response.diff
                            self.collectionView.reloadData()
                        }
                    } catch (let error) {
                        print(error)
                    }
                }
//            case .failure(let error):
//                print(error)
//            }
//        }
    }
}

extension DiffPrototypeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return dataSource?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let diffCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? DiffPrototypeCell,
        let item = dataSource?[safeIndex: indexPath.item] else {
            return UICollectionViewCell()
        }
        
        diffCell.configure(item: item, width: collectionView.bounds.width)
        
        return diffCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        return UICollectionReusableView()

//        guard kind == UICollectionView.elementKindSectionHeader,
//            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sectionHeaderReuseIdentifier, for: indexPath) as? DiffPrototypeSectionHeader,
//            let item = dataSource?[safeIndex: indexPath.item] else {
//            return UICollectionReusableView()
//        }
//
//        header.configure(text: group.sectionText)
//
//        return header
    }
}

extension DiffPrototypeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
//        guard let group = dataSource?[safeIndex: section] else {
//                return .zero
//        }
//
//        return CGSize(width: collectionView.bounds.width, height: group.sectionTextHeight + DiffPrototypeSectionHeader.paddingVertical)
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
    
    func cleaned() -> String {
        let cleanedContent = self.deletingPrefix("<td class=\"diff-addedline\">").deletingPrefix("<td class=\"diff-addedline\"/>").deletingPrefix("<td class=\"diff-deletedline\">").deletingPrefix("<td class=\"diff-deletedline\"/>").deletingPrefix("<td colspan=\"2\" class=\"diff-empty\">").deletingPrefix("<div>").deletingSuffix("</td>").deletingSuffix("</div>")
        
        let finalContent = cleanedContent.count > 0 ? cleanedContent : "\n"
        
        return finalContent
    }
}

extension StringProtocol {
    func nsRange(from range: Range<Index>) -> NSRange {
        return .init(range, in: self)
    }
}
