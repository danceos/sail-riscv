/* The emulator fetch-execute-interrupt dispatch loop. */

/* returns whether to increment the step count in the trace */
function step(step_no : int) -> bool = {
  /* for step extensions */
  ext_pre_step_hook();

  minstret_written = false;     /* see note for minstret */
  let (retired, stepped) : (Retired, bool) =
    match dispatchInterrupt(cur_privilege) {
      Some(intr, priv) => {
        if (fail_isSuppressedInterrupt(interruptType_to_bits(intr)) == false)
        then {
          if get_config_print_instr()
          then print_bits("Handling interrupt: ", interruptType_to_bits(intr));
          fail_onInterrupt(interruptType_to_bits(intr), false);
          handle_interrupt(intr, priv);
        };
        (RETIRE_FAIL, false)
      },
      None() => {
        fail_willExecuteInstruction(PC);
        fail_executeRequests();

        /* the extension hook interposes on the fetch result */
        /* Disable memory events while instruction is being fetched*/
        fail_setInstructionFetch(true);
        let f : FetchResult = ext_fetch_hook(fetch());
        /*Enable memory events*/
        fail_setInstructionFetch(false);
        match f {
          /* extension error */
          F_Ext_Error(e)   => {
            ext_handle_fetch_check_error(e);
            (RETIRE_FAIL, false)
          },
          /* standard error */
          F_Error(e, addr) => {
            handle_mem_exception(addr, e);
            (RETIRE_FAIL, false)
          },
          /* non-error cases: */
          F_RVC(h) => {
            let ast = decodeCompressed(h);
            if   get_config_print_instr()
            then {
              print_instr("[" ^ string_of_int(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(h) ^ ") " ^ to_str(ast));
            };
            /* check for RVC once here instead of every RVC execute clause. */
            if haveRVC() then {
              nextPC = PC + 2;
              let r: Retired = execute(ext_post_decode_hook(ast));
              fail_didExecuteInstruction(PC, EXTZ(h));
              (r, true)
             } else {
              handle_illegal();
              (RETIRE_FAIL, true)
             }
          },
          F_Base(w) => {
            let ast = decode(w);
            if   get_config_print_instr()
            then {
              print_instr("[" ^ string_of_int(step_no) ^ "] [" ^ to_str(cur_privilege) ^ "]: " ^ BitStr(PC) ^ " (" ^ BitStr(w) ^ ") " ^ to_str(ast));
            };
            nextPC = PC + 4;
            let r: Retired = execute(ext_post_decode_hook(ast));
            fail_didExecuteInstruction(PC, EXTZ(w));
            (r, true)
          }
        }
      }
    };


  tick_pc();

  /* update minstret */
  match retired {
    RETIRE_SUCCESS => retire_instruction(),
    RETIRE_FAIL    => ()
  };

  /* for step extensions */
  ext_post_step_hook();

  stepped
}

function loop () : unit -> unit = {
  let insns_per_tick = plat_insns_per_tick();
  i : int = 0;
  step_no : int = 0;
  while (~ (htif_done)) do {
    let stepped = step(step_no);
    if stepped then step_no = step_no + 1;

    /* check htif exit */
    if htif_done then {
      let exit_val = unsigned(htif_exit_code);
      if exit_val == 0 then print("SUCCESS")
      else print_int("FAILURE: ", exit_val);
      /* mask here and cause trap to FAIL */
      fail_onTrap(0x62);
      htif_done = false;
    } else {
      /* update time */
      i = i + 1;
      if i == insns_per_tick then {
        tick_clock();
        /* for now, we drive the platform i/o at every clock tick. */
        tick_platform();
        i = 0;
      }
    }
  }
}

/* initialize model state */
function init_model () -> unit = {
  init_platform (); /* devices */
  init_sys ();      /* processor */
  init_vmem ();     /* virtual memory */

  /* initialize extensions last */
  ext_init ();
  ext_init_regs ();
}
