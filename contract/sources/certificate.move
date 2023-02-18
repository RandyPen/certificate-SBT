module certificate_sbt::certificate {
    use std::string::{Self, String};
    use std::option::Option;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    // use sui::url::{Self, Url};  TODO: After Sui url module support URL format validation
    use sui::sui::SUI;

    
    // ======== Types =========
    struct AdminCap has key { id: UID }

    struct Treasury has key, store {
        id: UID,
        balance: Balance<SUI>,
        fee: u64,
    }

    struct CertificateRecord has key {
        id: UID,
        grantor: address,
        recipient: address,
        description: String,
        work: Option<String>,
        url: Option<String>,
    }

    struct CertificateReceived has key {
        id: UID,
        SBTID: address,
    }

    // ======== Events =========
    struct TreasuryCreated has copy, drop { id: ID }

    struct AwardCertification has copy, drop {
        SBTID: address,
        from: address,
        to: address
    }

    struct RevokeCertification has copy, drop {
        SBTID: address,
        from: address,
        to: address
    }

    struct UpdateMistakeFee has copy, drop {
        fee: u64
    }

    struct WithdrawFee has copy, drop {
        amount: u64
    }

    // ======== Errors =========
    const EWithdrawTooLarge: u64 = 0;

    const ENotGrantor: u64 = 1;

    const ENotEnoughPayment: u64 = 2;


    // ======== Functions =========

    fun init(ctx: &mut TxContext) {
        let id = object::new(ctx);

        event::emit(TreasuryCreated { id: object::uid_to_inner(&id) });

        transfer::transfer(AdminCap { id: object::new(ctx) }, tx_context::sender(ctx));
        transfer::share_object(Treasury {
            id,
            balance: balance::zero<SUI>(),
            fee: 1000000,
        })
    }

    public fun certificationIDinRecord(self: &CertificateRecord): address {
        object::uid_to_address(&self.id)
    }

    public fun grantor(self: &CertificateRecord): address {
        self.grantor
    }

    public fun description(self: &CertificateRecord): String {
        self.description
    }

    public fun work(self: &CertificateRecord): Option<String> {
        self.work
    }

    public fun image_url(self: &CertificateRecord): Option<String> {
        self.url
    }

    public fun certificationIDinReceived(self: &CertificateReceived): address {
        self.SBTID
    }

    public entry fun award(recipient: address, description: vector<u8>, work: vector<u8>, url: vector<u8>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let (sbtID, certificate_record) = new_certification_record(recipient, description, work, url, ctx);
        let certificate_received = new_certification_received(sbtID, ctx);

        event::emit(AwardCertification { SBTID: sbtID, from: sender, to: recipient });
        transfer::transfer(certificate_record, sender);
        transfer::transfer(certificate_received, recipient);
    }

    public entry fun revoke_grant(certificate: CertificateRecord, treasury: &mut Treasury, payment: Coin<SUI>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == grantor(&certificate), ENotGrantor);
        let treasury_balance = &mut treasury.balance;
        let payment_mut = &mut payment;
        let pay_coin = coin::split(payment_mut, treasury.fee, ctx);     // contains ENotEnoughPayment assert
        coin::put(treasury_balance, pay_coin);
        transfer::transfer(payment, sender);

        let CertificateRecord { id, grantor, recipient, description: _, work: _ , url: _ } = certificate;
        let sbtID: address = object::uid_to_address(&id);
        event::emit(RevokeCertification { SBTID: sbtID, from: grantor, to: recipient });
        object::delete(id)
    }

    // === Admin-only functionality ===
    public entry fun update_mistake_fee(
        self: &mut Treasury, _: &AdminCap, mistake_fee: u64
    ) {
        event::emit(UpdateMistakeFee { fee: mistake_fee });
        self.fee = mistake_fee
    }

    public entry fun withdraw(
        self: &mut Treasury, _: &AdminCap, amount: u64, ctx: &mut TxContext
    ) {
        let treasury_balance = &mut self.balance;
        assert!(balance::value(treasury_balance) >= amount, EWithdrawTooLarge);
        let withdraw_coin = coin::take(treasury_balance, amount, ctx);
        event::emit(WithdrawFee { amount: amount});
        transfer::transfer(withdraw_coin, tx_context::sender(ctx))
    }

    public entry fun withdraw_all(
        self: &mut Treasury, _: &AdminCap, ctx: &mut TxContext
    ) {
        let treasury_balance = &mut self.balance;
        let amount: u64 = balance::value(treasury_balance);
        let withdraw_coin = coin::take(treasury_balance, amount, ctx);
        event::emit(WithdrawFee { amount: amount});
        transfer::transfer(withdraw_coin, tx_context::sender(ctx))
    }

    // ============== Constructors. These create new Sui objects. ==============

    fun new_certification_record(
        recipient: address, description: vector<u8>, work: vector<u8>, url: vector<u8>, ctx: &mut TxContext
    ): (address, CertificateRecord) {
        let id = object::new(ctx);
        let sbtID: address = object::uid_to_address(&id);

        let certificate_record = CertificateRecord {
            id,
            grantor: tx_context::sender(ctx),
            recipient,
            description: string::utf8(description),
            work: string::try_utf8(work),
            url: string::try_utf8(url),
        };
        (sbtID, certificate_record)
    }

    fun new_certification_received(
        sbtID: address, ctx: &mut TxContext
    ): CertificateReceived {
        CertificateReceived {
            id: object::new(ctx),
            SBTID: sbtID,
        }
    }
}
