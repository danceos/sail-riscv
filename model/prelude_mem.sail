/* These functions define the primitives for physical memory access.
 * They depend on the XLEN of the architecture.
 *
 * They also depend on the type of metadata that is read and written
 * to physical memory.  For models that do not require this metadata,
 * a unit type can be used.
 *
 * The underlying __read_mem and __write_mem functions are from the
 * Sail library.  The metadata primitives __{Read,Write}RAM_Meta are
 * in prelude_mem_metadata.
 */


/* This is a slightly arbitrary limit on the maximum number of bytes
   in a memory access.  It helps to generate slightly better C code
   because it means width argument can be fast native integer. It
   would be even better if it could be <= 8 bytes so that data can
   also be a 64-bit int but CHERI needs 128-bit accesses for
   capabilities and SIMD / vector instructions will also need more. */
type max_mem_access : Int = 16

val write_ram = {lem: "write_ram", coq: "write_ram"} : forall 'n, 0 < 'n <= max_mem_access . (write_kind, xlenbits, atom('n), bits(8 * 'n), mem_meta, xlenbits) -> bool effect {wmv, wmvt}
function write_ram(wk, addr, width, data, meta, origin_pc) = {
  /* Write out metadata only if the value write succeeds.
   * It is assumed for now that this write always succeeds;
   * there is currently no return value.
   * FIXME: We should convert the external API for all backends
   * (not just for Lem) to consume the value along with the
   * metadata to ensure atomicity.
   */
  let ret : bool = __write_mem(wk, sizeof(xlen), addr, width, data);
  let memtype = sail_zero_extend(0b1, 8);
  fail_onMemoryWrite(addr, unsigned(data), width*8, memtype, origin_pc);
  if ret then __WriteRAM_Meta(addr, width, meta, origin_pc);
  ret
}

val write_ram_ea : forall 'n, 0 < 'n <= max_mem_access . (write_kind, xlenbits, atom('n)) -> unit effect {eamem}
function write_ram_ea(wk, addr, width) =
  __write_mem_ea(wk, sizeof(xlen), addr, width)

val read_ram = {lem: "read_ram", coq: "read_ram"} : forall 'n, 0 < 'n <= max_mem_access .  (read_kind, xlenbits, atom('n), bool, xlenbits) -> (bits(8 * 'n), mem_meta) effect {rmem, rmemt}
function read_ram(rk, addr, width, read_meta, origin_pc) = {
  let meta = if read_meta then __ReadRAM_Meta(addr, width, origin_pc) else default_meta;
  let value = __read_mem(rk, sizeof(xlen), addr, width);
  fail_onMemoryRead(addr, unsigned(value), width*8, fail_memtype_ram, origin_pc);
  (value, meta)
}

val __TraceMemoryWrite : forall 'n 'm. (atom('n), bits('m), bits(8 * 'n)) -> unit
val __TraceMemoryRead  : forall 'n 'm. (atom('n), bits('m), bits(8 * 'n)) -> unit
