# Zenswarm setup

Documentation of the Swarm of Oracles setup:

- Admin setup of cloud instances
- Admin setup and provisioning of Issuer
- Issuance of oracle keys
- Issuer provisioning of oracle scripts
- Admin update of issuer and oracle scripts 

## Issuer creation

```mermaid
sequenceDiagram
autonumber
  participant A as Admin
  participant C as Cloud
  participant I as Issuer
  A->A: Admin keygen (aSK + aPK)
  A->>C: Setup a Cloud provider
  C->>I: Issuer Install
  C->>A: Grant Issuer setup access
  A->>I: Issuer init + aPK
  I->I: Issuer keygen (iSK + iPK)
  I->>A: Issuer public key (iPK)
```

1. Admin is the control terminal and generates a new keypair (aSK + aPK)
1. Admin sets up a Cloud provider (one or more) can be remote or on-premises
1. Issuer is created by the Cloud provider and installed with a signed OS
1. Cloud grants to Admin setup access to the Issuer
1. Admin initialized the Issuer machine with signed scripts and the Admin public key
1. Issuer generates an issuer keypair (iSK + iPK)
1. Issuer shares its public key (iPK) with the Admin

## VM creation

```mermaid
sequenceDiagram
autonumber
  participant A as Admin
  participant C as Cloud
  participant I as Issuer
  participant V as VM1..VM2..VMn

  A->>C: Create VM
  C->>V: VM install and new IP
  C->>A: Grant VM setup access + IP
  A->>I: aSK signed registration of a new VM IP
  A->>V: Provision signed scripts + Issuer public key (iPK)
```

1. Admin orders the creation of a VM to the Cloud provider
1. Cloud provider creates the VM on a new allocated IP and installs a signed OS
1. Cloud provider grants the Admin setup access to the VM (IP + SSH)
1. Admin signs a message to register the new VM IP on the Issuer
1. Admin provisions the VM with a signed OS setup and the Issuer public key

## VM key issuance

```mermaid
sequenceDiagram
autonumber
  participant I as Issuer
  participant V as VM1..VM2..VMn

  I->I: Ephemeral keygen (eSK + ePK)
  I->>V: iSK signed request + eSK
  V->V: VM keygen (vSK + vPK)
  V->>I: eSK signed answer: IP + vPK
  I->I: ePK verify and store VM IP + vPK
```

1. Issuer generates an ephemeral keypair used only to verify the VM registration
1. Issuer signs the ephemeral secret key with iSK and sends a request to the VM IP
1. VM verifies the registration request with iPK and generates a VM keypair (vSK + vPK)
1. VM signs an answer with eSK and sends back its public key
1. Issuer verifies the answer signed with ePK and saves the VM public key and its IP

At the end of the process the ephemeral keys are discarded and the Issue has added to its database a new IP and its associated public key.

## Swarm operation
```mermaid
sequenceDiagram
autonumber
  participant U as User
  participant I as Issuer
  participant V as VM1..VM2..VMn
  U->>I: Swarm of Oracles API query
  I->>+V: propagate query to all VMs
  V->V: exec queries (TTL)
  V->>-I: return result or error
  I->I: consensus on results or errors
  I->>U: return collective result or error
```

1. A query is made to the Swarm of Oracles Issuer by a User (or an event or a time trigger)
1. Issuer parses and validates the query syntax, then propagates to all oracle VMs
1. VMs execute the Zencode associated to the query: may access other online services, query databases and external APIs
1. VMs return results of the Zencode execution or an error
1. Issuer verifies that all results are equal (full consensus) or raises an error
1. Issuer returns the verified result of the query or a list of specific errors occurred

## VM script update
```mermaid
sequenceDiagram
autonumber
  participant A as Admin
  participant I as Issuer
  participant V as VM1..VM2..VMn
  
  A->>I: aSK signed update ZIP
  I->I: aPK verify update ZIP
  I->>V: iSK signed update ZIP 
  V->V: iPK verify and install ZIP
```

1. Admin signs and uploads a ZIP with updated scripts
1. Issuer verifies the ZIP is signed by the Admin
1. Issuer signs and uploads the update ZIP to all VM
1. VM verifies the ZIP is signed by the Issuer and installs the scripts


## VM teardown
```mermaid
sequenceDiagram
autonumber
  participant A as Admin
  participant I as Issuer
  participant V as VM1..VM2..VMn
  
  A->>I: aSK signed shutdown + VM id
  I->I: aPK verify shutdown
  I->>V: iSK signed shutdown
  V->V: iPK verify and shutdown
  V->>I: vSK signed goodbye
  I->I: vPK verify and remove VM
```

1. Admin signs and sends a shutdown message for a certain VM
1. Issuer verifies message is signed by the Admin and the VM exists
1. Issuer signs sends the shutdown message to the VM
1. VM verifies the signed message
1. VM signs a goodbye message and sends it to the Issuer
1. Issuer verifies the goodbye message and removes the VM




