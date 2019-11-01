module Js = Js_of_ocaml.Js

let consolelog data =
  ignore
  @@ Js.Unsafe.fun_call
       (Js.Unsafe.js_expr "console.log")
       [|data |> Js.Unsafe.inject|]

let create_verification_key key_string =
  let key = Js.to_string key_string in
  let sexp = Core_kernel.Sexp.of_string key in
  consolelog "deserialize key" ;
  let key =
    Demo.Verification_key.t_of_sexp sexp
    |> Demo.Verification_key.Processed.create
  in
  consolelog key ; key

let decode_g1 a =
  let open Snarkette.Mnt6753 in
  let open Core_kernel in
  consolelog "deserialize g1" ;
  let a =
    Js.to_string a |> Sexp.of_string |> [%of_sexp: Fq.t * Fq.t] |> G1.of_affine
  in
  consolelog a ; a

let decode_g2 a =
  let open Snarkette.Mnt6753 in
  let open Core_kernel in
  consolelog "deserialize g2" ;
  let a =
    Js.to_string a |> Sexp.of_string
    |> [%of_sexp: (Fq.t * Fq.t * Fq.t) * (Fq.t * Fq.t * Fq.t)] |> G2.of_affine
  in
  consolelog a ; a

let construct_proof a b c delta_prime z =
  let a = decode_g1 a in
  let b = decode_g2 b in
  let c = decode_g1 c in
  let delta_prime = decode_g2 delta_prime in
  let z = decode_g1 z in
  {Demo.Proof.a; b; c; delta_prime; z}

let bigint_of_string s = Snarkette.Nat.of_string (Js.to_string s)

let bigint_to_string bi = Js.string (Snarkette.Nat.to_string bi)

let verify_state_hash verification_key state_hash proof =
  consolelog "deserialize state_hash" ;
  let input_nat = bigint_of_string state_hash in
  let open Snarkette in
  (* ... *)
  consolelog "run verify" ;
  let v =
    Demo.verify verification_key
      [Nat.shift_left input_nat 1; Nat.of_int 1]
      proof
  in
  consolelog v ;
  let v =
    Demo.verify verification_key
      [Nat.shift_left input_nat 1; Nat.of_int 1]
      proof
  in
  consolelog v ;
  let v =
    Demo.verify verification_key
      [Nat.shift_right input_nat 1; Nat.of_int 0]
      proof
  in
  consolelog v ;
  let v =
    Demo.verify verification_key
      [Nat.shift_right input_nat 1; Nat.of_int 0]
      proof
  in
  consolelog v ; consolelog "ran verify" ; v

let () =
  let window = Js.Unsafe.global in
  let snarkette_obj =
    let open Js.Unsafe in
    obj
      [| ("constructProof", inject construct_proof)
       ; ("createVerificationKey", inject create_verification_key)
       ; ("verifyStateHash", inject verify_state_hash)
       ; ("bigintOfString", inject bigint_of_string)
       ; ("bigintToString", inject bigint_to_string)
         (* ; ("hash", inject(call_hash)) *) |]
  in
  Js.Unsafe.set window "snarkette" snarkette_obj
