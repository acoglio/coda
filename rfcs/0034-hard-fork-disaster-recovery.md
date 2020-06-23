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

  - the scan state at the root (unless this is the "unsafe" case, and we're
     discarding the scan state)

    this is an instance of `Transaction_snark_scan_state.t`, retrievable via

	```ocaml
      let full = Transition_frontier.full_frontier frontier in
	  let protocol_states = full.protocol_states_for_root_scan_state in
	  State_hash.find_exn protocol_states root_hash

	```
    where `root_hash` is the Merkle root of the SNARKed ledger. (? is that how this map works ?)

The in-memory values (that is, those other than the epoch ledgers) can
be serialized as JSON or S-expressions to some particular location,
say `recovery_data` in the Coda configuration directory. The epoch
ledgers can be copied to that same location.

Creating and gossipping a hard fork block
-----------------------------------------

When the hard fork occurs, a restarted daemon gossips a special block
containing a new hard fork time, an epoch and slot. The type
`Gossip_net.Latest.T.msg` can be updated with a new alternative, say
`Last_fork_time`. Like an ordinary block, the special block contains a
protocol state, to be verified by the blockchain SNARK.  The unsafe
bits in an ordinary block are always `false`. In the special block,
those bits may be `true`.

In the case of a "safe" hard fork, where no unsafe bits are set, the
hard fork block contains the root protocol state we saved and its
proof. In the case of an unsafe hard fork, there can be a dummy proof.

Like an ordinary block, the special block contains a current protocol
version.  In the safe case, the patch version may be updated.  In the
unsafe case, the major version or minor versions must be updated,
forcing a software upgrade.

Verifying the blockchain for ordinary blocks is done using `update`
in the functor `Blockchain_snark.Blockchain_snark_state.Make`,
which relies on a `Snark_transition.t` input derived from a block.
For a hard fork, we'd write a new function that verifies that
the protocol state is the same as the old state, except for
those pieces indicated by unsafe bits.





- use epoch ledgers in the same way we'd use persisted epoch ledgers
- snarked ledger becomes new genesis ledger
   pass that ledger, and the protocol state to a variation on `Genesis_ledger_helper.Genesis_proof.generate_inputs`
    we have the `Protocol_state.value` already, don't need to calculate it

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

See RFCs 0032 and 0033 for how to handle the blockchain and scan state across
hard forks.

## Unresolved questions
[unresolved-questions]: #unresolved-questions
