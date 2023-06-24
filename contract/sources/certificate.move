module certificate_sbt::certificate {
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};

    // ======== Constants =========
    const VERSION: u64 = 1;
    const ONE_HOUR_IN_MS: u64 = 3_600_000;
    const ONE_YEAR_IN_MS: u64 = 31_536_000_000;
    
    // ======== Types =========
    struct AdminCap has key { id: UID }

    struct Treasury has key {
        id: UID,
        version: u64,
        balance: Balance<SUI>,
        penalty_fee: u64,
        renew_fee: u64,
    }

    struct Archieves has key {
        id: UID,
        version: u64,
        cabinet: Table<address, Files>,
    }

    struct Files has key, store {
        id: UID,
        file: Table<ID, u64>,
    }

    struct SoulBoundToken has key {
        id: UID,
        sender: address,
        recipient: address,
        title: String,
        description: Option<String>,
        work: Option<String>,
        image_url: Option<String>,
        thumbnail_url: Option<String>,
        start_time: u64,
        end_time: u64,
    }

    // ======== Events =========
    struct UpdateMistakeFee has copy, drop {
        fee: u64
    }

    struct UpdateReNewFee has copy, drop {
        fee: u64
    }

    struct WithdrawAmount has copy, drop {
        amount: u64
    }

    // ======== Errors =========
    const ENotEnough: u64 = 0;
    const EInvalidTime: u64 = 1;


    // ======== Functions =========

    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        let treasury = Treasury {
            id: object::new(ctx),
            version: VERSION,
            balance: balance::zero<SUI>(),
            penalty_fee: 500_000_000,
            renew_fee: 5_000_000,
        };
        let archieves = Archieves {
            id: object::new(ctx),
            version: VERSION,
            cabinet: table::new(ctx),
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
        transfer::share_object(treasury);
        transfer::share_object(archieves);
    }

    public entry fun mint(
        archieves: &mut Archieves,
        _recipient: address,
        _title: vector<u8>,
        _description: vector<u8>,
        _work: vector<u8>,
        _image_url: vector<u8>,
        _thumbnail_url: vector<u8>,
        _clk: &Clock,
        _effective_time: u64,
        ctx: &mut TxContext
    ) {
        let sender: address = tx_context::sender(ctx);
        if (!table::contains<address, Files>(&archieves.cabinet, sender)) {
            let files = Files { id: object::new(ctx), file: table::new<ID, u64>(ctx) };
            table::add(&mut archieves.cabinet, sender, files);
        }
    }

    // === Admin-only functionality ===
    public entry fun update_penalty_fee(
        treasury: &mut Treasury, _: &AdminCap, penalty_fee: u64
    ) {
        event::emit(UpdateMistakeFee { fee: penalty_fee });
        treasury.penalty_fee = penalty_fee
    }

    public entry fun update_renew_fee(
        treasury: &mut Treasury, _: &AdminCap, renew_fee: u64
    ) {
        event::emit(UpdateReNewFee { fee: renew_fee });
        treasury.renew_fee = renew_fee
    }

    public entry fun withdraw(
        treasury: &mut Treasury, _: &AdminCap, amount: Option<u64>, ctx: &mut TxContext
    ) {
        let amount = if (option::is_some(&amount)) {
            let amt = option::destroy_some(amount);
            assert!(amt <= balance::value(&treasury.balance), ENotEnough);
            amt
        } else {
            balance::value(&treasury.balance)
        };
        let withdraw_coin: Coin<SUI> = coin::take(&mut treasury.balance, amount, ctx);
        event::emit(WithdrawAmount { amount: amount});
        transfer::public_transfer(withdraw_coin, tx_context::sender(ctx))
    }

    // ============== Constructors. These create new Sui objects. ==============
    fun new_sbt(
        recipient: address,
        title: vector<u8>,
        description: vector<u8>,
        work: vector<u8>,
        image_url: vector<u8>,
        thumbnail_url: vector<u8>,
        clk: &Clock,
        effective_time: u64,
        ctx: &mut TxContext
        ): SoulBoundToken {
        assert!(0 < effective_time && effective_time <= ONE_YEAR_IN_MS, EInvalidTime);
        SoulBoundToken {
            id: object::new(ctx),
            sender: tx_context::sender(ctx),
            recipient,
            title: string::utf8(title),
            description: string::try_utf8(description),
            work: string::try_utf8(work),
            image_url: string::try_utf8(image_url),
            thumbnail_url: string::try_utf8(thumbnail_url),
            start_time: clock::timestamp_ms(clk),
            end_time: clock::timestamp_ms(clk) + effective_time,
        }
    }

}
