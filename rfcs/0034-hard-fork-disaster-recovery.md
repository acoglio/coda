## Summary
[summary]: #summary

This RFC explains how to a create a hard fork in response to a severe
failure in the Coda network.

## Motivation
[motivation]: #motivation

The Coda network may get to a state where the blockchain can no longer
make progress.  Symptoms might include many blockchain forks, or
blocks not being added at all, or repeated crashes of nodes. To
continue, a hard fork of the blockchain can be created, using an
updated version of the Coda software.

## Detailed design
[detailed-design]: #detailed-design

When it becomes evident that the network is failing, the Coda
developers will perform the following tasks:

 - on some node, run a CLI command to persist enough state to re-start the
    network

 - run a tool to transform the persisted state into startup data for the
    Coda binary

 - create a new Coda binary with a new major protocol version

 - notify node operators of the change, and provide access to the new
    binary and startup data

Other than the new protocol version and new startup data, the software
should not require any other changes. The new startup data results in
a new chain id, so the new software will require all node operators to
upgrade.

CLI command to save state
-------------------------

The Coda developers will choose a node with a root to represent the
starting point of the hard fork. That choice is beyond the scope of
this RFC, but one reasonable choice is an archive node run by
Coda developers.

The CLI command can be in the `internal` group of commands, since
it meant for use in extraordinary circumstances. A suggested
name is `save-hard-fork-data`. That command communicates with the
running node daemon via the daemon-RPC mechanism used in other
client commands.

Let `frontier` be the current transition frontier. When the daemon
receives the command, it saves the following data:

 - its root

   this is an instance of `Protocol_state.value`, retrievable via

	 ```ocaml
      let full = Transition_frontier.full_frontier frontier in
      let root = full.root in
	  root |> find_protocol_state
     ```

 - the SNARK (proof) for that root

   this is an instance of `Proof.t`, retrievable via

   ```ocaml
      let full = Transition_frontier.full_frontier frontier in
      let root = full.root in
      let (transition_with_hash,_) = root.validated_transition in
	  let transition = transition_with_hash.With_hash.data in
	  transition.protocol_state_proof
   ```

 - the SNARKed ledger corresponding to the root

   this is an instance of `Coda_base.Ledger.Any_ledger.witness`, retrievable
    via

   ```ocaml
    let full = Transition_frontier.full_frontier frontier in
    full.root_ledger
   ```
   Note: There appears to be a mechanism in `Persistent_root` for saving the
   root ledger, but it appears only to store a hash, and not the ledger entries.

 - the global slot number of the block containing the root

 - two epoch ledgers

   there is pending PR #4115 which allows saving epoch ledgers to RocksDB databases

   which two epoch ledgers needed depends on whether the root is in the current epoch,
     or the previous one:
	 - if the root is in the current epoch, the two ledgers needed are
	    `staking_epoch_snapshot` and `next_epoch_snapshot`, as in the PR
     - if the root is in the previous epoch, the two ledger needed are
        `staking_epoch_snapshot` and `previous_epoch_snapshot` (not implemented
	    in the PR)

Nodes running the upgraded software will have a new versions of

 - genesis ledger
 - genesis proof
 - genesis timestamp

and so will start with an empty root history. In earlier discussions
of hard forks, it was suggested that saving some length of root
history might be needed. See issue #4859. Because all nodes will be
starting from a new genesis state, they won't need to see any blocks
that led to that state; hence the root history won't need to be
persisted.

The in-memory values (that is, those other than the epoch ledgers) can
be serialized as JSON or S-expressions to some particular location,
say `recovery_data` in the Coda configuration directory. The epoch
ledgers can be copied to that same location.

Before saving any data, the networking layer should be disabled, so that all data
necessarily refers to the same state of the blockchain.

Transforming saved state to startup data
----------------------------------------

- use epoch ledgers in the same way we'd use persisted epoch ledgers
- snarked ledger becomes new genesis ledger
   pass that ledger, and the protocol state to a variation on `Genesis_ledger_helper.Genesis_proof.generate_inputs`
    we have the `Protocol_state.value` already, don't need to calculate it



======================================================================================


This is the technical portion of the RFC. Explain the design in sufficient detail that:

* Its interaction with other features is clear.
* It is reasonably clear how the feature would be implemented.
* Corner cases are dissected by example.

## Drawbacks
[drawbacks]: #drawbacks

In the best case, the network will run smoothly, making preparations
for a hard fork gratuitious, and the software unnecessarily
complex. That said, the cost of forgoing those preparations is high.

## Rationale and alternatives
[rationale-and-alternatives]: #rationale-and-alternatives

* Why is this design the best in the space of possible designs?
* What other designs have been considered and what is the rationale for not choosing them?
* What is the impact of not doing this?

## Prior art
[prior-art]: #prior-art

Discuss prior art, both the good and the bad, in relation to this proposal.

## Unresolved questions
[unresolved-questions]: #unresolved-questions

* What parts of the design do you expect to resolve through the RFC process before this gets merged?
* What parts of the design do you expect to resolve through the implementation of this feature before merge?
* What related issues do you consider out of scope for this RFC that could be addressed in the future independently of the solution that comes out of this RFC?
