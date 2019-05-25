//
//  SelectVisibleStatsViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 5/24/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit

class SelectDisplayedStatsViewController: UIViewController {
    
    @IBOutlet weak var displayedCollectionView: UICollectionView!
    @IBOutlet weak var hiddenCollectionView: UICollectionView!
    
    var patient = PatientModel()
    var displayed: [String] = []
    var hidden: [String] = []
    
    var hiddenGesture: UILongPressGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayedCollectionView.delegate = self
        displayedCollectionView.dataSource = self
        displayedCollectionView.dragDelegate = self
        displayedCollectionView.dropDelegate = self
        displayedCollectionView.dragInteractionEnabled = true
        hiddenCollectionView.delegate = self
        hiddenCollectionView.dataSource = self
        hiddenCollectionView.dragDelegate = self
        hiddenCollectionView.dropDelegate = self
        hiddenCollectionView.dragInteractionEnabled = true
        
        hiddenGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        displayedCollectionView.addGestureRecognizer(hiddenGesture)
        hiddenCollectionView.addGestureRecognizer(hiddenGesture)
        
        self.navigationItem.title = patient.name
        displayed = DatabaseModel.shared.getVisibleStats(for: patient.name)
        hidden = BREATH_METADATA.filter{ !displayed.contains($0) }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        DatabaseModel.shared.clearRecord(for: patient.name, in: TABLE_VISIBLE_STATS)
        DatabaseModel.shared.storeVisibleStats(displayed, for: patient.name)
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleGesture(_ gesture: UILongPressGestureRecognizer) {
        let collectionView: UICollectionView
        if gesture.view == displayedCollectionView {
            collectionView = displayedCollectionView
        }
        else {
            collectionView = hiddenCollectionView
        }
        switch gesture.state {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                break
            }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SelectDisplayedStatsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == displayedCollectionView {
            return displayed.count
        }
        else if collectionView == hiddenCollectionView {
            return hidden.count
        }
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "statItemSectionHeader", for: indexPath) as! BreathStatsHeaderCollectionReusableView
        if collectionView == displayedCollectionView {
            view.textLabel.text = "Displayed"
        }
        else if collectionView == hiddenCollectionView {
            view.textLabel.text = "Hidden"
        }
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "statItemCell", for: indexPath) as! StatCollectionViewCell
        if collectionView == displayedCollectionView {
            cell.textLabel.text = displayed[indexPath.row]
        }
        else if collectionView == hiddenCollectionView {
            cell.textLabel.text = hidden[indexPath.row]
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = self.dragItem(forItemAt: indexPath, in: collectionView)
        
        return [dragItem]
    }
    
    private func dragItem(forItemAt indexPath: IndexPath, in collectionView: UICollectionView) -> UIDragItem {
        var text = ""
        
        if collectionView == displayedCollectionView {
            text = displayed[indexPath.row]
        }
        else if collectionView == hiddenCollectionView {
            text = hidden[indexPath.row]
        }
        
        return UIDragItem(itemProvider: NSItemProvider(object: text as NSItemProviderWriting))
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        }
        else {
            destinationIndexPath = IndexPath(row: collectionView.numberOfItems(inSection: collectionView.numberOfSections - 1), section: collectionView.numberOfSections - 1)
        }

        coordinator.session.loadObjects(ofClass: NSString.self) { (items) in
            guard let texts = items as? [String] else {
                return
            }
            var sourceIndexPaths: [IndexPath] = []
            var destinationIndexPaths: [IndexPath] = []
            for (index, text) in texts.enumerated() {
                let indexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
                
                if collectionView == self.displayedCollectionView {
                    if self.hidden.contains(text) {
                        self.displayed.insert(text, at: indexPath.row)
                        self.hidden = self.hidden.filter{ $0 != text }
                        self.hiddenCollectionView.reloadData()
                        destinationIndexPaths.append(indexPath)
                    }
                    else {
                        guard let sourceIndexPath = coordinator.items.first?.sourceIndexPath else {
                            continue
                        }
                        self.displayed.insert(self.displayed.remove(at: sourceIndexPath.row), at: indexPath.row)
                        sourceIndexPaths.append(sourceIndexPath)
                        destinationIndexPaths.append(destinationIndexPath)
                    }
                }
                else if collectionView == self.hiddenCollectionView {
                    if self.displayed.contains(text) {
                        self.hidden.insert(text, at: indexPath.row)
                        self.displayed = self.displayed.filter{ $0 != text }
                        self.displayedCollectionView.reloadData()
                        destinationIndexPaths.append(indexPath)
                    }
                    else {
                        guard let sourceIndexPath = coordinator.items.first?.sourceIndexPath else {
                            continue
                        }
                        self.hidden.insert(self.hidden.remove(at: sourceIndexPath.row), at: indexPath.row)
                        sourceIndexPaths.append(sourceIndexPath)
                        destinationIndexPaths.append(destinationIndexPath)
                    }
                }
                else {
                    break
                }
                
            }
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: sourceIndexPaths)
                collectionView.insertItems(at: destinationIndexPaths)
            })
            //collectionView.insertItems(at: indexPaths)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let cell = collectionView.cellForItem(at: indexPath) as! StatCollectionViewCell
        let previewParams = UIDragPreviewParameters()
        previewParams.visiblePath = UIBezierPath(rect: cell.frame)
        return previewParams
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if collectionView == displayedCollectionView {
            displayed.insert(displayed.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
        }
        else if collectionView == hiddenCollectionView {
            hidden.insert(hidden.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
        }
    }
    
}
