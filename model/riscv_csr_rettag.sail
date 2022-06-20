register rtkey0 : xlenbits
register rtkey1 : xlenbits

mapping clause csr_name_map = 0x8c0 <-> "rtkey0"
mapping clause csr_name_map = 0x8c1 <-> "rtkey1"

function clause ext_is_CSR_defined (0x8c0, p) = p == Machine
function clause ext_is_CSR_defined (0x8c1, p) = p == Machine

function clause ext_read_CSR (0x8c0) = Some(rtkey0)
function clause ext_read_CSR (0x8c1) = Some(rtkey1)

function clause ext_write_CSR (0x8c0, value) = { rtkey0 = value; Some(rtkey0) }
function clause ext_write_CSR (0x8c1, value) = { rtkey1 = value; Some(rtkey1) }


