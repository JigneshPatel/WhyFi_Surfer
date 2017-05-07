//
//  TableViewController.swift
//  WhyFi
//
//  Created by 崔振宇 on 2017. 5. 4..
//  Copyright © 2017년 Tom. All rights reserved.
//

import UIKit
import Foundation
import KeychainAccess
import SwiftyJSON
import MessageUI
import UserNotifications
import SystemConfiguration



let count = 10;let time = 1000000;
let keychain = Keychain(service: "org.ShanghaiTech.WhyFi-token").synchronizable(true)
//let keychain = Keychain(server: "controller1.net.shanghaitech.edu.cn", protocolType: .https)
var firstTime = false;
var globalsuccess = true;

extension String {
    var localized: String {
        if let _ = UserDefaults.standard.string(forKey: "i18n_language") {} else {
            // we set a default, just in case
            UserDefaults.standard.set("en", forKey: "i18n_language")
            UserDefaults.standard.synchronize()
        }
        let lang = UserDefaults.standard.string(forKey: "i18n_language")
        
        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        _ = Bundle(path: path!)
        return NSLocalizedString(self, comment: "")
        //        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}

extension UITableViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UITableViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
class TableViewController: UITableViewController,UITextFieldDelegate,MFMailComposeViewControllerDelegate {
    @IBOutlet var dataTableView: UITableView!
    @IBOutlet weak var txfUserName: UITextField!
    @IBOutlet weak var txfPassword: UITextField!
    @IBOutlet weak var switchRem: UISwitch!
    @IBOutlet weak var switchAutoLogin: UISwitch!
    @IBOutlet weak var lblLogin: UILabel!
    @IBOutlet weak var lblMsg: UILabel!
    @IBOutlet weak var loginTableViewCell: UITableViewCell!
    @IBOutlet weak var lblConnectMsg: UILabel!
    @IBOutlet weak var connectTableViewCell: UITableViewCell!

    func completePing (timeElapsed:Double?, error:Error?){
        if timeElapsed != nil {
            let wifiName = network().getSSID()
            if wifiName != nil {
                let alertController = UIAlertController(title: "Success".localized, message: String(format:"Network is OK".localized+"withWiFi".localized,"\(wifiName!)"), preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK".localized, style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }else{
                let alertController = UIAlertController(title: "Success".localized, message: "Network is OK".localized+"withCell".localized, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK".localized, style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        if error != nil {
            let wifiName = network().getSSID()
            if wifiName != nil {
                let alertController = UIAlertController(title: "Fail".localized, message: String(format:"Network is not OK".localized+"withWiFi".localized,"\(wifiName!)"), preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK".localized, style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }else{
                let alertController = UIAlertController(title: "Fail".localized, message: "Network is not OK".localized+"withCell".localized, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "OK".localized, style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }

        DispatchQueue.main.async(execute: {
            self.lblConnectMsg.text = "CheckInternet".localized
            self.lblConnectMsg.textColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            self.connectTableViewCell.selectionStyle = UITableViewCellSelectionStyle.default
        })

    }
    
    func isInternetAvailable()
    {
        PlainPing.ping("baidu.com", withTimeout: 3.0,completionBlock: completePing)
    }

    func refresh(refreshControl: UIRefreshControl) {
        DispatchQueue.main.async(execute: {
            self.dataTableView.refreshControl?.attributedTitle = NSAttributedString(string: "Authenticating. This may take a while.".localized)
        })
        DispatchQueue.global(qos: .background).async {
            if self.clickLogin(hint: true,auto: true){
                DispatchQueue.main.async(execute: {
                    self.dataTableView.refreshControl?.attributedTitle = NSAttributedString(string: "Success. Welcome to the Internet.".localized)
                })
                sleep(1);
            }else{
                DispatchQueue.main.async(execute: {
                    self.dataTableView.refreshControl?.attributedTitle = NSAttributedString(string: "Failed. Response is not correct.".localized)
                })
                sleep(1);
            }
            self.dataTableView.refreshControl?.endRefreshing()
        }
        DispatchQueue.main.async(execute: {
            self.dataTableView.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh".localized)
        })
    }
    override func viewWillAppear(_ animated: Bool) {

        if !UserDefaults.standard.bool(forKey: "UserAlreadyPopedNotification"){
            let alertController = UIAlertController(title: "Notify".localized, message: "NotifyDetail".localized, preferredStyle: UIAlertControllerStyle.alert)
            
            let settingsAction = UIAlertAction(title: "OK".localized, style: .default) { (_) -> Void in
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                    (granted, error) in
                    //Parse errors and track state
                    if granted {
                        print("Yay!")
                    } else {
                        let alertController = UIAlertController(title: "NotifyCancelled".localized, message: "NotifyCancelledDetail".localized, preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "OK".localized, style: UIAlertActionStyle.default, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    }
                    UserDefaults.standard.set(true, forKey: "UserAlreadyPopedNotification")
                }
            }
            alertController.addAction(settingsAction)
            self.present(alertController, animated: true, completion: nil)
            

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("shown\n");
        dataTableView.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh".localized)
        
        dataTableView.refreshControl?.addTarget(self, action: #selector(TableViewController.refresh(refreshControl:)), for: UIControlEvents.valueChanged)
        
        self.txfUserName.delegate = self
        self.txfPassword.delegate = self
        
        switchRem.isOn = UserDefaults.standard.bool(forKey: "remember")
        switchAutoLogin.isOn = UserDefaults.standard.bool(forKey:"auto");
        
        if switchRem.isOn {

            txfUserName.text = UserDefaults.standard.string(forKey: "username")
            if UserDefaults.standard.string(forKey: "username") != nil{
                txfPassword.text = keychain[UserDefaults.standard.string(forKey: "username")!]
            }
        }
        if switchAutoLogin.isOn{
            DispatchQueue.global(qos: .background).async {
                if self.loginTableViewCell.selectionStyle != UITableViewCellSelectionStyle.none {
                    DispatchQueue.global(qos: .background).async {
                        if self.loginTableViewCell.selectionStyle != UITableViewCellSelectionStyle.none {
                            DispatchQueue.main.async(execute: {
                                self.lblLogin.textColor = #colorLiteral(red: 0.7233663201, green: 0.7233663201, blue: 0.7233663201, alpha: 1)
                                self.txfPassword.isEnabled = false
                                self.txfUserName.isEnabled = false
                                self.switchAutoLogin.isEnabled = false
                                self.switchRem.isEnabled = false
                                self.loginTableViewCell.selectionStyle = UITableViewCellSelectionStyle.none
                            })
                            self.clickLogin(hint: true,auto: false);
                            DispatchQueue.main.async(execute: {
                                self.lblLogin.textColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
                                self.txfPassword.isEnabled = true
                                self.txfUserName.isEnabled = true
                                self.switchAutoLogin.isEnabled = true
                                self.switchRem.isEnabled = true
                                self.loginTableViewCell.selectionStyle = UITableViewCellSelectionStyle.default
                            })
                        }
                    }
                }
            }
        }
        //setMinimumBackgroundFetchInterval(600)

        self.hideKeyboardWhenTappedAround()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
 */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath){
        print("section: \(indexPath.section)")
        print("row: \(indexPath.row)")
        if indexPath.section == 1 && indexPath.row == 0{

            DispatchQueue.global(qos: .background).async {
                if self.loginTableViewCell.selectionStyle != UITableViewCellSelectionStyle.none {
                    DispatchQueue.main.async(execute: {
                        self.lblLogin.textColor = #colorLiteral(red: 0.7233663201, green: 0.7233663201, blue: 0.7233663201, alpha: 1)
                        self.txfPassword.isEnabled = false
                        self.txfUserName.isEnabled = false
                        self.switchAutoLogin.isEnabled = false
                        self.switchRem.isEnabled = false
                        self.loginTableViewCell.selectionStyle = UITableViewCellSelectionStyle.none
                    })
                    self.clickLogin(hint: true,auto: false);
                    DispatchQueue.main.async(execute: {
                        self.lblLogin.textColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
                        self.txfPassword.isEnabled = true
                        self.txfUserName.isEnabled = true
                        self.switchAutoLogin.isEnabled = true
                        self.switchRem.isEnabled = true
                        self.loginTableViewCell.selectionStyle = UITableViewCellSelectionStyle.default
                    })
                }
            }
  
        }else if indexPath.section == 2 && indexPath.row == 0{
            sendEmail()
        }
        if indexPath.section == 2 {
            switch indexPath.row{
            case 1:
                guard let settingsUrl = URL(string: "App-Prefs:root=WIFI") else {
                    return
                    
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
                break
            case 2:
                if self.connectTableViewCell.selectionStyle != UITableViewCellSelectionStyle.none{
                    DispatchQueue.main.async(execute: {
                        self.lblConnectMsg.text = "Checking. Please wait.".localized
                        self.lblConnectMsg.textColor = #colorLiteral(red: 0.7233663201, green: 0.7233663201, blue: 0.7233663201, alpha: 1)
                        self.connectTableViewCell.selectionStyle = UITableViewCellSelectionStyle.none
                    })
                    self.isInternetAvailable()
                }

                break
            case 3:
                UIApplication.shared.openURL(URL(string: "https://controller1.net.shanghaitech.edu.cn:8445/PortalServer/customize/1478262836414/phone/auth.jsp")!)
                break
            default:break
            }
        }
        dataTableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    func syncRequest(ip:String)->Bool{
        var success = false

        // Check request result
        for i in 1...count{
            DispatchQueue.main.async(execute: {
                self.lblMsg.text = String(format:"Authenticating. This may take a while N".localized,"\(i)","\(count)")
                
            })
            print("pro\(i)")
            let a = ip
            var ansrequest = URLRequest(url: URL(string: "https://controller1.net.shanghaitech.edu.cn:8445/PortalServer/Webauth/webAuthAction!syncPortalAuthResult.action")!)
            let anspostString = "authLan=zh_CN&hasValidateCode=False&validCode=&hasValidateNextUpdatePassword=true&rememberPwd=false&browserFlag=zh&hasCheckCode=false&checkcode=&saveTime=14&autoLogin=false&userMac=&isBoardPage=false&browserFlag=zh&clientIp=\(a)"
            ansrequest.httpBody = anspostString.data(using: .utf8)
            let anstask = URLSession.shared.dataTask(with: ansrequest) { data, response, error in
                guard let data = data, error == nil else {                                                 // check for
                    return
                }
                let responseString = String(data: data, encoding: .utf8)
                print("ANSWER_String = \(responseString ?? "")")
                if let dataFromString = responseString?.data(using: .utf8, allowLossyConversion: false) {
                    do {
                        let json = try JSON(data: dataFromString)
                        if json["data"]["portalAuthStatus"] == 1{
                            success = true
                            
                        }
                    }catch {
                    }
                }
            }
            anstask.resume()
            //anstask.resume()
            if success{
                break
            }
            if !globalsuccess{
                globalsuccess = true;
                DispatchQueue.main.async(execute: {
                    self.lblMsg.text = String(format:"Fail".localized)
                })
                anstask.cancel();
                return false
            }
            usleep(2500000);
        }
        
        if success{
            DispatchQueue.main.async(execute: {
                self.lblMsg.text = "Success. Welcome to the Internet.".localized;
            })
            if UserDefaults.standard.bool(forKey: "remember") == true && self.txfUserName != nil{
                UserDefaults.standard.set(self.txfUserName.text!, forKey: "username")
                do {
                    try keychain
                        .synchronizable(true)
                        .set(self.txfPassword.text!, key: self.txfUserName.text!)
                } catch let error {
                    print("error: \(error)")
                }
            }
            return true;
        }else{
            DispatchQueue.main.async(execute: {
                self.lblMsg.text = "Failed. Response is not correct.".localized
            })
            return false;
        }
        
    }
    
    func wifiNetworkWrong(type:Int32,name:String!){
        let alertController = UIAlertController (title: "wrongWiFi".localized, message: "noWifiConnect".localized, preferredStyle: .alert)
        if type == 2 {
            alertController.title = "wrongWiFi".localized
            alertController.message = String(format:"SSID is not ShanghaiTech.\n You are now connecting %@.".localized,"\(name!)");
        }
        let settingsAction = UIAlertAction(title: "Wi-Fi Settings".localized, style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: "App-Prefs:root=WIFI") else {
                return
                
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Close".localized, style: .default, handler: nil)
        alertController.addAction(cancelAction)
        DispatchQueue.main.async(execute: {
            self.present(alertController, animated: true, completion: nil)
        })
        
    }
    
    func clickLogin(hint: Bool,auto:Bool)->Bool{
        var ip = ""
        //var status:Int32 = 0;
        var username:String = "";
        var password:String = "";
        

        if txfUserName == nil || txfPassword == nil {
            if UserDefaults.standard.string(forKey: "username") != nil{
                username = UserDefaults.standard.string(forKey: "username")!
            }
            
            if UserDefaults.standard.string(forKey: "username") != nil{
                password = keychain[UserDefaults.standard.string(forKey: "username")!]!
            }
        }else{
            if  txfUserName.text != nil && txfPassword.text != nil{
                username = txfUserName.text!
                password = txfPassword.text!
            }
        }
        
        if username != "" && password != "" {
            let wifiName = network().getSSID()
            guard wifiName != nil else {
                wifiNetworkWrong(type: 1,name:wifiName)
                return false;
            }
            if wifiName == "ShanghaiTech" || wifiName == "guest"{
                DispatchQueue.main.async(execute: {
                    self.lblMsg.text = "Authenticating. This may take a while.".localized
                    
                })
                var request = URLRequest(url: URL(string: "https://controller1.net.shanghaitech.edu.cn:8445/PortalServer/Webauth/webAuthAction!login.action")!)
                //request = URLRequest(url: URL(string: "https://controller1.net.shanghaitech.edu.cn:8445/PortalServer/customize/1478262836414/pc/auth.jsp")!)
                request.httpMethod = "POST"
                let postString = "userName=\(username)&password=\(password)&authLan=zh_CN&hasValidateCode=False&validCode=&hasValidateNextUpdatePassword=true&rememberPwd=false&browserFlag=zh&hasCheckCode=false&checkcode=&saveTime=14&autoLogin=false&userMac=&isBoardPage=false"
                request.httpBody = postString.data(using: .utf8)
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data, error == nil else {                                                 // check for fundamental networking error
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {  // check for http errors
                        if hint {
                            DispatchQueue.main.async(execute: {
                                self.lblMsg.text = "Failed. Network is problematic.".localized
                            })
                        }
                    }
                    let responseString = String(data: data, encoding: .utf8)
                    print("RESPONSE\n")
                    let a:String = responseString!
                    print("responseString = \(a)")
                    // sleep(100);
                    if let dataFromString = a.data(using: .utf8, allowLossyConversion: true) {
                        
                        do{
                            let json = try JSON(data: dataFromString)
                            ip = json["data"]["ip"].stringValue
                            //status = json["data"]["accessStatus"].int32!
                            if json["data"]["accessStatus"] != 200{
                                globalsuccess = false;
                                let alertController = UIAlertController(title: "Message From Server".localized, message: json["message"].stringValue, preferredStyle: UIAlertControllerStyle.alert)
                                alertController.addAction(UIAlertAction(title: "OK".localized, style: UIAlertActionStyle.default, handler: nil))
                                self.present(alertController, animated: true, completion: nil)
                                
                                
                            }else{
                                
                            }
                            
                        }catch{
                        }
                    }
                    
                    
                }
                task.resume()
                
                return self.syncRequest(ip: ip);
       
                
            }else{
                
                wifiNetworkWrong(type: 2,name:wifiName)
                return false;
            }
        }
        else{
            if !auto{
                DispatchQueue.main.async(execute: {
                    let alertController = UIAlertController(title: "Empty Username or Password".localized, message: "Please fill in the blanks!".localized, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "OK".localized, style: UIAlertActionStyle.default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                })
                return false;
            }
        }
        return false;
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            // Configure the fields of the interface.
            composeVC.setToRecipients([""])
            composeVC.setSubject("title".localized)
            composeVC.setMessageBody("content".localized, isHTML: false)
            if let filePath = Bundle.main.path(forResource: "ShanghaiTech", ofType: "mobileconfig") {
                
                if let fileData = NSData(contentsOfFile: filePath) {
                    
                    composeVC.addAttachmentData(fileData as Data, mimeType: "mobileconfig", fileName: "ShanghaiTech.mobileconfig")
                }
            }
            // Present the view controller modally.
            self.present(composeVC, animated: true, completion: nil)
        } else {
            // show failure alert
        }
    }
    

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.txfUserName{
            self.txfPassword.becomeFirstResponder()
        }else{
            self.view.endEditing(true)
        }
        
        return false
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Check the result or perform other tasks.
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func memSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(switchRem.isOn, forKey: "remember")
        if !switchRem.isOn {
            if UserDefaults.standard.string(forKey: "username") != nil{
                keychain[UserDefaults.standard.string(forKey: "username")!] = nil;
            }
            UserDefaults.standard.set("", forKey: "username")
            switchAutoLogin.isOn = false;
            UserDefaults.standard.set(switchAutoLogin.isOn, forKey: "auto")
        }
    }

    @IBAction func autoSwitchChanged(_ sender: UISwitch) {
        if switchAutoLogin.isOn {
            switchRem.isOn = true
            UserDefaults.standard.set(switchRem.isOn, forKey: "remember")
        }
        UserDefaults.standard.set(switchAutoLogin.isOn, forKey: "auto")
    }
    
}
