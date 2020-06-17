let Prelude = ../External/Prelude.dhall

let Cmd = ../Lib/Cmds.dhall

let r = Cmd.run

let commands : List Cmd.Type =
  [
    let libp2p_dir = "src/app/libp2p_helper"
    let cache_file = "${libp2p_dir}/result/bin/libp2p_helper"

    in

    Cmd.cacheThrough
      Cmd.Docker::{
        image = (../Constants/ContainerImages.dhall).codaToolchain,
        extraEnv = [ "LIBP2P_NIXLESS=1", "GO=/usr/lib/go/bin/go" ]
      }
      cache_file
      Cmd.CompoundCmd::{
        preprocess = r "echo preprocess",
        postprocess = r "echo postprocess",
        inner = r "make libp2p_helper"
      }
  ]

in

{ commands = commands }
