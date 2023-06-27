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
    const NINETY_DAYS_IN_MS: u64 = 7_776_000_000;
    const ONE_YEAR_IN_MS: u64 = 31_536_000_000;
    
    // ======== Types =========
    struct AdminCap has key { id: UID }

    struct Treasury has key {
        id: UID,
        version: u64,
        balance: Balance<SUI>,
        revoke_fee: u64,
        renew_fee: u64,
        mint_fee: u64,
    }

    struct Archieves has key {
        id: UID,
        version: u64,
        cabinet: Table<address, Files>,
    }

    struct Files has store {
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
    struct MintSBT has copy, drop {
        from: address,
        to: address,
        sbt_id: ID,
    }

    struct RenewSBT has copy, drop {
        sbt_id: ID,
    }

    struct RevokeSBT has copy, drop {
        sbt_id: ID,
    }

    struct BurnSBT has copy, drop {
        sbt_id: ID,
    }

    struct UpdateRevokeFee has copy, drop {
        fee: u64
    }

    struct UpdateReNewFee has copy, drop {
        fee: u64
    }

    struct UpdateMintFee has copy, drop {
        fee: u64
    }

    struct WithdrawAmount has copy, drop {
        amount: u64
    }

    // ======== Errors =========
    const ENotEnough: u64 = 0;
    const EInvalidTime: u64 = 1;
    const EInvalidSBT: u64 = 2;
    const EInvalidSBTID: u64 = 3;
    const EInvalidSender: u64 = 4;
    const EAlreadyRevoke: u64 = 5;
    const EBurnValidSBT: u64 = 6;

    // ======== Functions =========

    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        let treasury = Treasury {
            id: object::new(ctx),
            version: VERSION,
            balance: balance::zero<SUI>(),
            revoke_fee: 50_000_000,
            renew_fee: 500_000,
            mint_fee: 500_000,
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

    // ======== SBT Manipulate Functions =========
    public entry fun mint(
        archieves: &mut Archieves,
        treasury: &mut Treasury,
        fee: &mut Coin<SUI>,
        recipient: address,
        title: vector<u8>,
        description: vector<u8>,
        work: vector<u8>,
        image_url: vector<u8>,
        thumbnail_url: vector<u8>,
        clk: &Clock,
        effective_time: Option<u64>,
        ctx: &mut TxContext
    ) {
        let sender: address = tx_context::sender(ctx);
        if (!table::contains<address, Files>(&archieves.cabinet, sender)) {
            let files = Files { id: object::new(ctx), file: table::new<ID, u64>(ctx) };
            table::add(&mut archieves.cabinet, sender, files);
        };

        let fee_coin: Coin<SUI> = coin::split(fee, treasury.mint_fee, ctx);
        coin::put(&mut treasury.balance, fee_coin);

        let effective_time: u64 = if (option::is_some(&effective_time)) {
            let ef_time = option::destroy_some(effective_time);
            assert!(0 < ef_time && ef_time <= ONE_YEAR_IN_MS, EInvalidTime);
            ef_time
        } else {
            NINETY_DAYS_IN_MS
        };

        let sbt: SoulBoundToken = new_sbt(recipient, title, description, work, image_url, thumbnail_url,clk, effective_time, ctx);

        let sbt_id: ID = object::id(&sbt);
        let files: &mut Files = table::borrow_mut(&mut archieves.cabinet, sender);
        table::add(&mut files.file, sbt_id, effective_time);

        event::emit(MintSBT{ from: sender, to: recipient, sbt_id: sbt_id });
        transfer::transfer(sbt, recipient);
    }

    public entry fun renew(
        archieves: &Archieves,
        treasury: &mut Treasury,
        fee: &mut Coin<SUI>,
        sbt: &mut SoulBoundToken,
        clk: &Clock,
        ctx: &mut TxContext
    ) {
        let files: &Files = table::borrow(&archieves.cabinet, sbt.sender);
        let effective_time: u64 = *table::borrow(&files.file, object::id(sbt));
        assert!(effective_time > 0, EInvalidSBT);

        let fee_coin: Coin<SUI> = coin::split(fee, treasury.renew_fee, ctx);
        coin::put(&mut treasury.balance, fee_coin);

        sbt.end_time = clock::timestamp_ms(clk) + effective_time;
        event::emit(RenewSBT{ sbt_id: object::id(sbt) });
    }

    public entry fun revoke(
        archieves: &mut Archieves,
        treasury: &mut Treasury,
        fee: &mut Coin<SUI>,
        sbt_id: ID,
        ctx: &mut TxContext
    ) {
        let sender: address = tx_context::sender(ctx);
        assert!(table::contains<address, Files>(&archieves.cabinet, sender), EInvalidSender);

        let files: &mut Files = table::borrow_mut(&mut archieves.cabinet, sender);
        assert!(table::contains<ID, u64>(&files.file, sbt_id), EInvalidSBTID);

        let effective_time: &mut u64 = table::borrow_mut(&mut files.file, sbt_id);
        assert!(*effective_time > 0, EAlreadyRevoke);

        let fee_coin: Coin<SUI> = coin::split(fee, treasury.revoke_fee, ctx);
        coin::put(&mut treasury.balance, fee_coin);

        *effective_time = 0;
        event::emit(RevokeSBT{ sbt_id: sbt_id });
    }

    public entry fun burn(
        archieves: &mut Archieves,
        sbt: SoulBoundToken
    ) {
        let SoulBoundToken { id, sender, recipient: _, title: _, description: _, work: _, image_url: _, thumbnail_url: _, start_time: _, end_time: _ } = sbt;
        let files: &mut Files = table::borrow_mut(&mut archieves.cabinet, sender);
        let sbt_id: ID = object::uid_to_inner(&id);
        let effective_time: &u64 = table::borrow(&files.file, sbt_id);
        assert!(*effective_time == 0, EBurnValidSBT);
        let _ = table::remove(&mut files.file, sbt_id);
        object::delete(id);
        event::emit(BurnSBT { sbt_id: sbt_id });
    }

    // ======== SBT Getter Functions =========
    public fun sender(sbt: &SoulBoundToken): address {
        sbt.sender
    }

    public fun recipient(sbt: &SoulBoundToken): address {
        sbt.recipient
    }

    public fun title(sbt: &SoulBoundToken): String {
        sbt.title
    }

    public fun description(sbt: &SoulBoundToken): Option<String> {
        sbt.description
    }

    public fun work(sbt: &SoulBoundToken): Option<String> {
        sbt.work
    }

    public fun start_time(sbt: &SoulBoundToken): u64 {
        sbt.start_time
    }

    public fun end_time(sbt: &SoulBoundToken): u64 {
        sbt.end_time
    }

    // === Admin-only functionality ===
    public entry fun update_revoke_fee(
        treasury: &mut Treasury, _: &AdminCap, revoke_fee: u64
    ) {
        event::emit(UpdateRevokeFee { fee: revoke_fee });
        treasury.revoke_fee = revoke_fee
    }

    public entry fun update_renew_fee(
        treasury: &mut Treasury, _: &AdminCap, renew_fee: u64
    ) {
        event::emit(UpdateReNewFee { fee: renew_fee });
        treasury.renew_fee = renew_fee
    }

    public entry fun update_mint_fee(
        treasury: &mut Treasury, _: &AdminCap, mint_fee: u64
    ) {
        event::emit(UpdateMintFee { fee: mint_fee });
        treasury.mint_fee = mint_fee
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
