module certificate_sbt::certificate {
    use std::string::{Self, String};
    use std::option::Option;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct CertificateRecord has key {
        id: UID,
        grantor: address,
        recipient: address,
        description: String,
        work: Option<String>,
    }

    struct CertificateReceived has key {
        id: UID,
        recordID: address,
    }

    const ENotGrantor: u64 = 1;

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

    public fun certificationIDinReceived(self: &CertificateReceived): address {
        self.recordID
    }

    public entry fun award(recipient: address, description: vector<u8>, work: vector<u8>, ctx: &mut TxContext) {
        let (recordID, certificate_record) = new_certification_record(recipient, description, work, ctx);
        transfer::transfer(certificate_record, tx_context::sender(ctx));

        let certificate_received = new_certification_received(recordID, ctx);
        transfer::transfer(certificate_received, recipient);
    }

    public entry fun revoke_grant(certificate: CertificateRecord, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == grantor(&certificate), ENotGrantor);
        let CertificateRecord { id, grantor: _, recipient: _, description: _, work: _ } = certificate;
        object::delete(id);
    }

    // ============== Constructors. These create new Sui objects. ==============

    fun new_certification_record(
        recipient: address, description: vector<u8>, work: vector<u8>, ctx: &mut TxContext
    ): (address, CertificateRecord) {
        let id = object::new(ctx);
        let recordID: address = object::uid_to_address(&id);

        let certificate_record = CertificateRecord {
            id,
            grantor: tx_context::sender(ctx),
            recipient,
            description: string::utf8(description),
            work: string::try_utf8(work),
        };
        (recordID, certificate_record)
    }

    fun new_certification_received(
        recordID: address, ctx: &mut TxContext
    ): CertificateReceived {
        CertificateReceived {
            id: object::new(ctx),
            recordID,
        }
    }
}