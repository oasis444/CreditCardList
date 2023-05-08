//
//  CardListVC.swift
//  CreditCardList
//
//  Copyright (c) 2023 oasis444. All right reserved.
//

import UIKit
import Kingfisher
import FirebaseDatabase
import FirebaseFirestore

class CardListVC: UITableViewController {
    
    var creditCardList: [CreditCard] = []
//    var ref: DatabaseReference!
    var db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UITableView Cell Register
        let nibName = UINib(nibName: "CardListCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "CardListCell")
        
        // RealTime DB 읽기
//        ref = Database.database().reference()
//        ref.observe(.value) { snapshot in
//            guard let value = snapshot.value as? [String: [String: Any]] else { return }
//
//            do {
//                let jsonData = try JSONSerialization.data(withJSONObject: value)
//                let cardData = try JSONDecoder().decode([String: CreditCard].self, from: jsonData)
//                let cardList = Array(cardData.values)
//                self.creditCardList = cardList.sorted { $0.rank < $1.rank }
//
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//            } catch let error {
//                print("Error JSON Parsing: \(error.localizedDescription)")
//            }
//        }
        
        // Firestore 읽기
        db.collection("creditCardList").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error Firestore fetching document: \(String(describing: error?.localizedDescription))")
                return
            }
            self.creditCardList = documents.compactMap { doc -> CreditCard? in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: doc.data())
                    let creditCard = try JSONDecoder().decode(CreditCard.self, from: jsonData)
                    return creditCard
                } catch let error {
                    print("Error Json Parsing: \(error)")
                    return nil
                }
            }.sorted { $0.rank < $1.rank }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension CardListVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creditCardList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardListCell", for: indexPath) as? CardListCell else { return UITableViewCell() }
        cell.rankLabel.text = "\(creditCardList[indexPath.row].rank)위"
        cell.promotionLabel.text = "\(creditCardList[indexPath.row].promotionDetail.amount)만원 증정"
        cell.cardNameLabel.text = "\(creditCardList[indexPath.row].name)"
        let imageURL = URL(string: creditCardList[indexPath.row].cardImageURL)
        cell.cardImageView.kf.setImage(with: imageURL)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "CardDetailVC") as? CardDetailVC else { return }
        vc.promotionDetail = creditCardList[indexPath.row].promotionDetail
        self.navigationController?.pushViewController(vc, animated: true)
        
        // Realtime DB 쓰기
        // Option 1
//        let cardID = creditCardList[indexPath.row].id
//        ref.child("Item\(cardID)/isSelected").setValue(true)
        
        // Option 2 (경로를 모르는 경우)
//        ref.queryOrdered(byChild: "id").queryEqual(toValue: cardID).observe(.value) { [weak self] snapshot in
//            guard let self = self,
//            let value = snapshot.value as? [String: [String: Any]],
//            let key = value.keys.first else { return }
//            self.ref.child("\(key)/isSelected").setValue(true)
//        }
        
        // Firestore 쓰기
        // Option 1
        let cardID = creditCardList[indexPath.row].id
        db.collection("creditCardList").document("card\(cardID)").updateData(["isSelected": true])
        
        // Option 2 (경로를 모르는 경우)
//        db.collection("creditCardList").whereField("id", isEqualTo: cardID).getDocuments { snapshot, error in
//            guard let document = snapshot?.documents.first else {
//                print("Error Firestore fetching document")
//                return
//            }
//            document.reference.updateData(["isSelected": true])
//        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Realtime DB 삭제
            // Option 1
//            let cardID = creditCardList[indexPath.row].id
//            ref.child("Item\(cardID)").removeValue()
            
            // Option 2
//            ref.queryOrdered(byChild: "id").queryEqual(toValue: cardID).observe(.value) { [weak self] snapshot in
//                guard let self = self,
//                      let value = snapshot.value as? [String: [String: Any]],
//                      let key = value.keys.first else { return }
//                ref.child(key).removeValue()
//            }
            
            // Firestore 삭제
            let cardID = creditCardList[indexPath.row].id
            
            // Option 1
            self.db.collection("creditCardList").document("card\(cardID)").delete()
            
            // Option 2
//            self.db.collection("creditCardList").whereField("id", isEqualTo: cardID).getDocuments { snapshot, error in
//                guard let document = snapshot?.documents.first else {
//                    print("Error Firestore fetching document: \(String(describing: error))")
//                    return
//                }
//                document.reference.delete()
//            }
        }
    }
}
