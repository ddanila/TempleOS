#ifndef I386_MEMORY_BACKING_CONFIG_INCLUDED
#define I386_MEMORY_BACKING_CONFIG_INCLUDED
//Match the public small-allocation batch, avoiding a second layer of reserve.
//This native backing policy does not change allocation/page rounding.
#define I386_NATIVE_BACKING_QUANTUM 8192
//Retain 128 KiB across automatic trims for fresh task startup. Larger
//graphics allocations still grow on demand without retaining a full-size pool.
#define I386_NATIVE_STARTUP_RESERVE_PAGES 256
#endif
