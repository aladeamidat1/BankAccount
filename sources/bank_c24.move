
module bank_c24::bank_c24{


    use std::string::String;
    use sui::table;
    use std::address;
    use sui::object::delete;
    use sui::table::drop;
    use sui::tx_context::dummy;


    const EBankNotFound: u64 = 0;
    const EAccountNotFound: u64 = 1;
    const EAccountNotAdded: u64 = 3;
    const EAccountAlreadyExists: u64 = 4;
    const EBalanceNotCorrect: u64 = 5;
    const EDepositLesserThanZero: u64 = 6;


    public struct Account has key, store {
        id: UID,
        name: String,
        pin: String,
        balance: u64
    }

    public struct Bank has key, store {
        id: UID,
        name: String,
        accounts: table::Table<address, Account>
    }

    public fun create_bank(name: String, ctx: &mut TxContext): Bank{
        let id = object::new(ctx);
        let accounts = table::new<address, Account>(ctx);

        Bank{
            id,
            name,
            accounts
        }

    }
    
    public fun create_account(name: String, pin: String, ctx: &mut TxContext): Account{
        let id = object::new(ctx);

        Account{
            id,
            name,
            pin,
            balance: 0
        }

    }


    public fun add_account_to_bank(user_address: address, account_to_be_added: Account, bank: &mut Bank){
        assert!(!bank.accounts.contains(user_address), EAccountAlreadyExists);
        bank.accounts.add(user_address, account_to_be_added);

    }

    public fun dummy_drop(obj: Bank, user: address){
        transfer::public_transfer(obj, user)
    }

    public fun deposit(bank: &mut Bank, user_address: address, amount: u64){
        assert!(amount > 0, EDepositLesserThanZero);
        let user_account =  table::borrow_mut<address, Account>(&mut bank.accounts, user_address);
        user_account.balance = user_account.balance + amount;
    }

    public fun withdraw(bank: &mut Bank, user_address: address, amount: u64){
        let user_account =  table::borrow_mut<address, Account>(&mut bank.accounts, user_address);
        assert!(user_account.balance >= amount, EBalanceNotCorrect);
        user_account.balance = user_account.balance - amount;
    }


    public fun create_receiver_account(bank: &mut Bank, receiver_address: address, name: String, pin: String, ctx: &mut TxContext){
        assert!(!bank.accounts.contains(receiver_address), EAccountAlreadyExists);
        let receiver_account = create_account(name, pin, ctx);
        bank.accounts.add(receiver_address, receiver_account);
    }



    public fun transfer(bank: &mut Bank, user_address: address, amount: u64, receiver_address: address , ctx: &mut TxContext){
        assert!(bank.accounts.contains(user_address), EBalanceNotCorrect);

        if (!bank.accounts.contains(receiver_address)){
            create_receiver_account(bank , receiver_address,b"Diko".to_string(), b"0000".to_string(), ctx);
        }

        let user_account =  table::borrow_mut<address, Account>(&mut bank.accounts, user_address);
        assert!(user_account.balance >= amount, EBalanceNotCorrect);
        user_account.balance = user_account.balance - amount;

        let receiver_account =  table::borrow_mut<address, Account>(&mut bank.accounts, receiver_address);
        receiver_account.balance = receiver_account.balance + amount;
    }


    
    #[test]
    public fun test_create_bank() {
        let mut ctx = dummy();

        let mut zenith_bank = create_bank(b"Zenith".to_string(), &mut ctx);
        assert!(zenith_bank.name == b"Zenith".to_string(), EBankNotFound);

        let amidat_account = create_account(b"amidat".to_string(), b"1234".to_string(), &mut ctx);
        assert!(amidat_account.name == b"amidat".to_string(), EAccountNotFound);
        assert!(amidat_account.pin == b"1234".to_string(), EAccountNotFound);

        let user_address = @amidat_address;


        add_account_to_bank(user_address, amidat_account,&mut zenith_bank);
        dummy_drop(zenith_bank, @bank_address);

    }

    #[test]
    public fun test_deposit() {
        let mut ctx = dummy();

        let mut zenith_bank = create_bank(b"Zenith".to_string(), &mut ctx);
        assert!(zenith_bank.name == b"Zenith".to_string(), EBankNotFound);

        let amidat_account = create_account(b"amidat".to_string(), b"1234".to_string(), &mut ctx);
        assert!(amidat_account.name == b"amidat".to_string(), EAccountNotFound);
        assert!(amidat_account.pin == b"1234".to_string(), EAccountNotFound);

        let user_address = @amidat_address;


        add_account_to_bank(user_address, amidat_account,&mut zenith_bank);
        assert!(zenith_bank.accounts.contains(user_address), EAccountNotFound);
        let user_account =  table::borrow_mut<address, Account>(&mut zenith_bank.accounts, user_address);

        assert!(user_account.balance == 0, EBalanceNotCorrect);

        deposit(&mut zenith_bank, user_address, 1000);
        
        let user_account =  table::borrow_mut<address, Account>(&mut zenith_bank.accounts, user_address);

        assert!(user_account.balance == 1000, EBalanceNotCorrect);

        dummy_drop(zenith_bank, @bank_address);

    }

    #[test]
    public fun test_withdraw(){
        let mut ctx = dummy();

        let mut zenith_bank = create_bank(b"Zenith".to_string(), &mut ctx);
        assert!(zenith_bank.name == b"Zenith".to_string(), EBankNotFound);

        let amidat_account = create_account(b"amidat".to_string(), b"1234".to_string(), &mut ctx);
        assert!(amidat_account.name == b"amidat".to_string(), EAccountNotFound);
        assert!(amidat_account.pin == b"1234".to_string(), EAccountNotFound);

        let user_address = @amidat_address;

        add_account_to_bank(user_address, amidat_account,&mut zenith_bank);
        assert!(zenith_bank.accounts.contains(user_address), EAccountNotFound);

        deposit(&mut zenith_bank, user_address, 1000);

        let user_account =  table::borrow_mut<address, Account>(&mut zenith_bank.accounts, user_address);
        assert!(user_account.balance == 1000, EBalanceNotCorrect);

        withdraw(&mut zenith_bank, user_address, 500);

        let user_account =  table::borrow_mut<address, Account>(&mut zenith_bank.accounts, user_address);
        assert!(user_account.balance == 500, EBalanceNotCorrect);

        dummy_drop(zenith_bank, @bank_address);

    }

    
    #[test]
    public fun test_transfer(){
        let mut ctx = dummy();

        let mut zenith_bank = create_bank(b"zenith".to_string(), &mut ctx);
        assert!(zenith_bank.name == b"zenith".to_string(), EBankNotFound);

         let amidat_account = create_account(b"amidat".to_string(), b"1234".to_string(), &mut ctx);
        assert!(amidat_account.name == b"amidat".to_string(), EAccountNotFound);
        assert!(amidat_account.pin == b"1234".to_string(), EAccountNotFound);

        let user_address= @amidat_address;

        add_account_to_bank(user_address, amidat_account, &mut zenith_bank);
        assert!(zenith_bank.accounts.contains(user_address), EAccountNotFound);

        deposit(&mut zenith_bank, user_address, 1000);

        let user_account =  table::borrow_mut<address, Account>(&mut zenith_bank.accounts, user_address);
        assert!(user_account.balance == 1000, EBalanceNotCorrect);

        let receiver_address= @diko_address;
        transfer(&mut zenith_bank , user_address, 300, receiver_address,&mut ctx);

        assert!(receiver_account.balance == 300, EBalanceNotCorrect);

        assert!(user_account.balance == 700, EBalanceNotCorrect);
        
        dummy_drop(zenith_bank, @bank_address);
    }
}