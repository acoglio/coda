[%%import
"/src/config.mlh"]

[%%ifdef
consensus_mechanism]

[%%else]

module Random_oracle = Random_oracle_nonconsensus.Random_oracle
module Coda_compile_config =
  Coda_compile_config_nonconsensus.Coda_compile_config

[%%endif]

open Core_kernel
open Hash_prefixes

let salt (s : Hash_prefixes.t) = Random_oracle.salt (s :> string)

let receipt_chain = salt receipt_chain

let coinbase = salt coinbase

let pending_coinbases = salt pending_coinbases

let coinbase_stack_data = salt coinbase_stack_data

let coinbase_stack_state_hash = salt coinbase_stack_state_hash

let coinbase_stack = salt coinbase_stack

let checkpoint_list = salt checkpoint_list

let merge_snark = salt merge_snark

let base_snark = salt base_snark

let protocol_state = salt protocol_state

let protocol_state_body = salt protocol_state_body

let merkle_tree =
  let f i = salt (merkle_tree i) in
  (* Cache up to the compiled ledger depth. *)
  let cached = ref [||] in
  fun i ->
    let len = Array.length !cached in
    if i >= len then
      cached :=
        Array.append !cached
          (Array.init (i + 1 - len) ~f:(fun i -> f (i + len))) ;
    !cached.(i)

let coinbase_merkle_tree =
  let f i = salt (coinbase_merkle_tree i) in
  let cached = ref [||] in
  fun i ->
    let len = Array.length !cached in
    if i >= len then
      cached :=
        Array.append !cached
          (Array.init (i + 1 - len) ~f:(fun i -> f (i + len))) ;
    !cached.(i)

let vrf_message = salt vrf_message

let signature = salt signature

let vrf_output = salt vrf_output

let epoch_seed = salt epoch_seed

let transition_system_snark = salt transition_system_snark

let account = salt account
