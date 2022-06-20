/* ****************************************************************** */
/* This file specifies the instructions in the 'RETTAG' extension.    */
/* ****************************************************************** */



val retkey_pac  = {c: "retkey_pac"} : (xlenbits, xlenbits, xlenbits, xlenbits) -> xlenbits
val retkey_aut  = {c: "retkey_aut"} : (xlenbits, xlenbits, xlenbits, xlenbits) -> xlenbits

union clause ast = PAC : (regidx, regidx, regidx)

mapping clause encdec = PAC(rs2, rs1, rd)  <-> 0b0000000 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0001011

function clause execute (PAC(rs2, rs1, rd)) = {
    let ptr_val = X(rs1);
    let code_val = X(rs2);
    let res_val = retkey_pac(rtkey0, rtkey1, ptr_val, code_val);
    X(rd) = res_val;
    RETIRE_SUCCESS
}

mapping clause assembly = PAC(rs2, rs1, rd)
  <-> "pac" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)



union clause ast = AUT : (regidx, regidx, regidx)

mapping clause encdec = AUT(rs2, rs1, rd)  <-> 0b0000001 @ rs2 @ rs1 @ 0b110 @ rd @ 0b0001011

function clause execute (AUT(rs2, rs1, rd)) = {
    let enc_ptr_val = X(rs1);
    let code_val = X(rs2);
    let ptr_val = retkey_aut(rtkey0, rtkey1, enc_ptr_val, code_val);
    
    if (bit_to_bool(ptr_val[63])) then {
        handle_exception(E_Extension(EXC_RETTAG));
        RETIRE_FAIL
    } else {
        X(rd) = ptr_val;
        RETIRE_SUCCESS
    }
}

mapping clause assembly = AUT(rs2, rs1, rd)
  <-> "aut" ^ spc() ^ reg_name(rd) ^ sep() ^ reg_name(rs1) ^ sep() ^ reg_name(rs2)
