# SBT Certification

A Sui based SBT Certification.

## Demo 

[Demo Link](https://certificate-sbt.vercel.app/)

## Entry Function

```Rust
public entry fun award(recipient: address, description: vector<u8>, work: vector<u8>, ctx: &mut TxContext)

public entry fun revoke_grant(certificate: CertificateRecord, ctx: &mut TxContext)
```
