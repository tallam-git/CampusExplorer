
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Firebase
import FirebaseFirestoreSwift
import FirebaseDatabase


class FireStoreManager {
   
   public static let shared = FireStoreManager()
   var hospital = [String]()
   var storageRef: StorageReference!

   var db: Firestore!
   var dbRef : CollectionReference!
   var gallary : CollectionReference!
   
   init() {
       let settings = FirestoreSettings()
       Firestore.firestore().settings = settings
       db = Firestore.firestore()
       dbRef = db.collection("Users")
       gallary = db.collection("Gallary")
       storageRef = Storage.storage().reference()
   }
    
    
    func fetchDataFromFirestore(collectionView:UICollectionView) {
        // Assuming you have a reference to the "Images" document in your Firestore
        let documentReference = FireStoreManager.shared.gallary.document("Images")

        // Add a listener to get real-time updates
        documentReference.addSnapshotListener { (documentSnapshot, error) in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if document.exists {
                // Document exists, try to extract the "imageUrls" array
                if let imageUrls = document.data()?["imageUrls"] as? [String] {
                    // Update the local images array
                    gallaryImages = imageUrls

                    // Reload the collection view to reflect the changes
                    collectionView.reloadData()
                    
                    if(firstTimeNot) {
                        if(gallaryImages.count > 2) {
                            let lastItemIndex = IndexPath(item: gallaryImages.count - 1, section: 0)
                            collectionView.scrollToItem(at: lastItemIndex, at: .bottom, animated: true)
                        }
                    }
                   
                } else {
                    print("Document doesn't contain 'imageUrls' field or it is not an array.")
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    
    
    func uploadImageToStorage(imageData: Data, completion: @escaping (String?) -> ()) {
            let imageName = UUID().uuidString
            let imageRef = storageRef.child("gallery/\(imageName).jpg")

            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            _ = imageRef.putData(imageData, metadata: metadata) { (metadata, error) in
                guard error == nil else {
                    // Handle error
                    print("Error uploading image to storage: \(error!.localizedDescription)")
                    completion(nil)
                    return
                }

                imageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        // Handle error
                        print("Error getting download URL: \(error?.localizedDescription ?? "")")
                        completion(nil)
                        return
                    }

                    completion(downloadURL.absoluteString)
                }
            }
        }
    
    func saveImageURLToFirestore(url: String) {
        // Assuming you have a document ID where you want to store the image URLs
        let documentID = "Images" // Replace with your actual document ID
        
        // Get the reference to the document
        let documentReference = gallary.document(documentID)

        // Check if the document exists
        documentReference.getDocument { (document, error) in
            if let document = document, document.exists {
                // Document exists, update the array field with the new image URL
                documentReference.updateData(["imageUrls": FieldValue.arrayUnion([url])]) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                    } else {
                        print("Document updated successfully with image URL: \(url)")
                    }
                }
            } else {
                // Document doesn't exist, create a new document with the image URL
                documentReference.setData(["imageUrls": [url]]) { error in
                    if let error = error {
                        print("Error creating document: \(error)")
                    } else {
                        print("Document created successfully with image URL: \(url)")
                    }
                }
            }
        }
    }

    
    
    func getAllBuildings(completion: @escaping ([CampusBuilding])->()) {
       
        db.collection("Buildings").getDocuments { (querySnapshot, err) in
            
             if let err = err {
                    print("Error getting documents: \(err)")
                    completion([])
                } else {
                    var list: [CampusBuilding] = []
                    for document in querySnapshot!.documents {
                        do {
                            let temp = try document.data(as: CampusBuilding.self)
                            list.append(temp)
                        }catch let error {
                            print(error)
                        }
                    }
                    completion( list)
                }
            }
    }
    
    func getAllFaculties(completion: @escaping ([Faculty])->()) {
       
        db.collection("Faculties").getDocuments { (querySnapshot, err) in
            
             if let err = err {
                    print("Error getting documents: \(err)")
                    completion([])
                } else {
                    var list: [Faculty] = []
                    for document in querySnapshot!.documents {
                        do {
                            let temp = try document.data(as: Faculty.self)
                            list.append(temp)
                        }catch let error {
                            print(error)
                        }
                    }
                    completion( list)
                }
            }
    }
    
    func getAllEvents(completion: @escaping ([Event])->()) {
        db.collection("Event").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion([])
            } else {
                var list: [Event] = []
                for document in querySnapshot!.documents {
                    do {
                        let temp = try document.data(as: Event.self)
                        list.append(temp)
                    } catch let error {
                        print(error)
                    }
                }
                completion(list)
            }
        }
    }
   
   func signUp(email:String,name:String,password:String) {
       
       self.checkAlreadyExistAndSignup(name:name,email:email,password:password)
   }

   
   func login(email:String,password:String,completion: @escaping (Bool)->()) {
       let  query = db.collection("Users").whereField("email", isEqualTo: email)
       
       query.getDocuments { (querySnapshot, err) in
        
           if(querySnapshot?.count == 0) {
               showAlerOnTop(message: "Email not found!!")
           }else {

               for document in querySnapshot!.documents {
                   print("doclogin = \(document.documentID)")
                   UserDefaults.standard.setValue("\(document.documentID)", forKey: "documentId")

                   if let pwd = document.data()["password"] as? String{

                       if(pwd == password) {

                           let name = document.data()["name"] as? String ?? ""
                           let email = document.data()["email"] as? String ?? ""
                           let password = document.data()["password"] as? String ?? ""
                           
                           UserDefaultsManager.shared.saveData(name: name, email: email, password: password)
                           completion(true)

                       }else {
                           showAlerOnTop(message: "Password doesn't match")
                       }


                   }else {
                       showAlerOnTop(message: "Something went wrong!!")
                   }
               }
           }
       }
  }
       
   func getPassword(email:String,password:String,completion: @escaping (String)->()) {
       let  query = db.collection("Users").whereField("email", isEqualTo: email)
       
       query.getDocuments { (querySnapshot, err) in
        
           if(querySnapshot?.count == 0) {
               showAlerOnTop(message: "Email id not found!!")
           }else {

               for document in querySnapshot!.documents {
                   print("doclogin = \(document.documentID)")
                   UserDefaults.standard.setValue("\(document.documentID)", forKey: "documentId")
                   if let pwd = document.data()["password"] as? String{
                           completion(pwd)
                   }else {
                       showAlerOnTop(message: "Something went wrong!!")
                   }
               }
           }
       }
  }
   
   func checkAlreadyExistAndSignup(name:String,email:String,password:String) {
       
       getQueryFromFirestore(field: "email", compareValue: email) { querySnapshot in
            
           print(querySnapshot.count)
           
           if(querySnapshot.count > 0) {
               showAlerOnTop(message: "This Email is Already Registerd!!")
           }else {
               
               // Signup
               
               let data = ["name":name,"email":email,"password":password] as [String : Any]
               
               self.addDataToFireStore(data: data) { _ in
                   
                 
                   showOkAlertAnyWhereWithCallBack(message: "Registration Success!!") {
                        
                       DispatchQueue.main.async {
                           SceneDelegate.shared?.loginCheckOrRestart()
                       }
                      
                   }
                   
               }
              
           }
       }
   }
   
   func getQueryFromFirestore(field:String,compareValue:String,completionHandler:@escaping (QuerySnapshot) -> Void){
       
       dbRef.whereField(field, isEqualTo: compareValue).getDocuments { querySnapshot, err in
           
           if let err = err {
               
               showAlerOnTop(message: "Error getting documents: \(err)")
                           return
           }else {
               
               if let querySnapshot = querySnapshot {
                   return completionHandler(querySnapshot)
               }else {
                   showAlerOnTop(message: "Something went wrong!!")
               }
              
           }
       }
       
   }
   
   func addDataToFireStore(data:[String:Any] ,completionHandler:@escaping (Any) -> Void){
       let dbr = db.collection("Users")
       dbr.addDocument(data: data) { err in
                  if let err = err {
                      showAlerOnTop(message: "Error adding document: \(err)")
                  } else {
                      completionHandler("success")
                  }
    }
       
       
   }
    
    func addEvent(event: Event ,completion: @escaping (Bool)->()) {
        let eventData = ["eventName":event.eventName, "date": event.date, "description": event.description, "dateTimeStamp": event.dateTimeStamp] as [String : Any]
        self.db.collection("Event").addDocument(data: eventData) { err in
            if let err = err {
                showAlerOnTop(message: "Error adding document: \(err)")
            } else {
                completion(true)
            }
        }
    }
    
    
    func deleteEvent(eventName: String, date: String, completion: @escaping (Bool)->()) {
            let eventsCollection = db.collection("Event")

            // Construct a query to find the event with the specified eventName and date
            let query = eventsCollection
                .whereField("eventName", isEqualTo: eventName)
                .whereField("date", isEqualTo: date)

            query.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }

                for document in documents {
                    // Delete the document from Firestore
                    eventsCollection.document(document.documentID).delete { error in
                        if let error = error {
                            print("Error deleting document: \(error.localizedDescription)")
                        } else {
                            completion(true)
                            print("Document deleted successfully")
                        }
                    }
                }
            }
        }
}
