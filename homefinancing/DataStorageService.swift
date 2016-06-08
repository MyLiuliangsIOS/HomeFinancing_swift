//
//  DataStorageService.swift
//  homefinancing
//
//  Created by 辰 宫 on 5/8/16.
//  Copyright © 2016 wph. All rights reserved.
//

class DataStorageService: GCBaseStorage {
    
    static let sharedInstance = DataStorageService()
    private override init() {}
    
    // MARK: - typeList
    internal func getAccountTypeList(type:AccountType) -> Array<AccountTypeModel> {
        
        var typeArray = [AccountTypeModel]()
        
        if type == AccountType.pay {
            for payDict in defaultPayTypeArray {
                let payTypeModel:AccountTypeModel = AccountTypeModel(dict: payDict)
                typeArray.append(payTypeModel)
            }
        } else {
            for incomeDict in defaultIncomeTypeArray {
                let incomeTypeModel:AccountTypeModel = AccountTypeModel(dict: incomeDict)
                typeArray.append(incomeTypeModel)
            }
        }
        
        return typeArray
    }
    
    // MARK: - add
    internal func addAccountToDatabase(accountModel:AccountModel) {
        self.deleteAccountWithId(accountModel.id!)
        self.insertToTableWithModel(accountModel)
    }
    
    // MARK: - getList
    internal func getHomeTableSourceListByMonth(monthStr:String) -> (array:Array<AccountGroupStruct>,payTotal:String,incomeTotal:String,surplus:String) {
        let accountModelArray = getAccountListByMonth(monthStr)
        
        var groupStructArray:Array<AccountGroupStruct> = []
        var groupStruct:AccountGroupStruct?
        var totalPayAmount:Int = 0
        var totalIncomeAmount:Int = 0
        for accountModel in accountModelArray {
            if accountModel.payOrIncome == String(AccountType.pay) {
                totalPayAmount = totalPayAmount + Int(accountModel.amount!)!
            } else {
                totalIncomeAmount = totalIncomeAmount + Int(accountModel.amount!)!
            }
            if (groupStruct == nil) {
                groupStruct = createGroupStructWith(accountModel)
                groupStructArray.append(groupStruct!)
            } else {
                //if same day, plus
                if groupStruct?.dayDateStr == accountModel.accountDate {
                    let originPayAmount:Int = Int((groupStruct?.payAmount)!)!
                    let originIncomAmount:Int = Int((groupStruct?.incomeAmount)!)!
                    if accountModel.payOrIncome == String(AccountType.pay) {
                        groupStruct?.payAmount = String(originPayAmount + Int(accountModel.amount!)!)
                    } else {
                        groupStruct?.incomeAmount = String(originIncomAmount + Int(accountModel.amount!)!)
                    }
                    groupStruct?.accountModelArray.append(accountModel)
                    //因为struct不同于class，不是引用传递，会自动复制，所以需要重新替换一下
                    groupStructArray[groupStructArray.count - 1] = groupStruct!
                } else { //create new struct
                    groupStruct = createGroupStructWith(accountModel)
                    groupStructArray.append(groupStruct!)
                }
            }
        }
        
        return (groupStructArray,String(totalPayAmount),String(totalIncomeAmount),String(totalIncomeAmount - totalPayAmount))
    }
    
    private func getAccountListByMonth(monthStr:String) -> Array<AccountModel> {
        let resultArr = self.selectModelArrayByClass(object_getClass(AccountModel()), params: ["accountMonthDate": monthStr], orderBy: "updateDate", isDesc: true)
        return resultArr as! Array<AccountModel>
    }
    
    private func createGroupStructWith(accountModel:AccountModel) -> AccountGroupStruct {
        var payAmount:String = "0"
        var incomeAmount:String = "0"
        if accountModel.payOrIncome == String(AccountType.pay) {
            payAmount = accountModel.amount!
        } else {
            incomeAmount = accountModel.amount!
        }
        var groupStruct:AccountGroupStruct = AccountGroupStruct(payAmount: payAmount,incomeAmount: incomeAmount,centerDateStr: dayCnStringWithDateStr(accountModel.accountDate!)!,dayDateStr: accountModel.accountDate!,accountModelArray: [])
        groupStruct.accountModelArray.append(accountModel)
        
        return groupStruct
    }
    
    private func dayCnStringWithDateStr(dateStr:String) -> String? {
        var dayCnString:String?
        if dateStr.characters.count > 9 {
            if NSDate.dateDayStringWithStandardFormat(NSDate()) == dateStr {
                dayCnString = "今天"
            } else {
                let offset = dateStr.startIndex.advancedBy(8)
                dayCnString = dateStr.substringFromIndex(offset) + "日"
            }
        }
        return dayCnString
    }
    
    // MARK: - getList
    internal func deleteAccountWithId(accountId:String) {
        self.deleteFromTableByClass(object_getClass(AccountModel()), params: ["id":accountId])
    }
}
