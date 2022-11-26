#[test_only]
module certificate_sbt::certificate_tests {
    use certificate_sbt::certificate::{Self, CertificateRecord, CertificateReceived, award, revoke_grant, description, work, certificationIDinRecord, certificationIDinReceived};
    use std::string::{Self, utf8, try_utf8};

    const GRANTOR: address = @0xAACC;
    const RECEIVER: address = @0xBBBB;
    const SORRY: vector<u8> = vector[83, 111, 114, 114, 121];    // "Sorry" in ASCII.
    const URGOOD: vector<u8> = vector[85, 82, 71, 79, 79, 68];   // "URGOOD" in ASCII.

    #[test]
    fun test_award() {
        use sui::test_scenario;

        let scenario_val = test_scenario::begin(GRANTOR);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, GRANTOR);
        {
            award(RECEIVER, SORRY, URGOOD, test_scenario::ctx(scenario));

            let certification_record = test_scenario::take_from_sender<CertificateRecord>(scenario);
            assert!(description(&certification_record) == string::utf8(SORRY), 1);
            assert!(work(&certification_record) == string::try_utf8(URGOOD), 1);
            
            let certification_received = test_scenario::take_from_address<CertificateReceived>(scenario, RECEIVER);
            assert!(certificationIDinReceived(&certification_received) == certificationIDinRecord(&certification_record), 1);

            test_scenario::return_to_address(RECEIVER, certification_received);
            test_scenario::return_to_sender(scenario, certification_record)
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_revoke_grant() {
        use sui::test_scenario;

        let scenario_val = test_scenario::begin(GRANTOR);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, GRANTOR);
        {
            award(RECEIVER, SORRY, URGOOD, test_scenario::ctx(scenario));
            let certification_record = test_scenario::take_from_sender<CertificateRecord>(scenario);
            revoke_grant(certification_record, test_scenario::ctx(scenario));
        };
        test_scenario::end(scenario_val);
    }
}