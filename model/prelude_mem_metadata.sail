/* The default metadata carries no information, and is implemented
 * using a unit type.
 */

type mem_meta = unit

let default_meta : mem_meta = ()

val __WriteRAM_Meta : forall 'n. (xlenbits, atom('n), mem_meta, xlenbits) -> unit effect {wmvt}
function __WriteRAM_Meta(addr, width, meta, origin_pc) = ()

val __ReadRAM_Meta  : forall 'n. (xlenbits, atom('n), xlenbits) -> mem_meta effect {rmem}
function __ReadRAM_Meta(addr, width, origin_pc) = ()
