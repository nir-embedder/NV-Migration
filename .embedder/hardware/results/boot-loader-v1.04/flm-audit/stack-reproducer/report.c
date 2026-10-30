
#include <stdint.h>
static void out(const char *text) {
    register uint32_t r0 __asm__("r0") = 4;
    register const char *r1 __asm__("r1") = text;
    __asm__ volatile("bkpt 0xab" : "+r"(r0) : "r"(r1) : "memory");
}
__attribute__((noreturn)) static void done(uint32_t status) {
    uint32_t args[2] = {0x20026, status};
    register uint32_t r0 __asm__("r0") = 0x20;
    register uint32_t *r1 __asm__("r1") = args;
    __asm__ volatile("bkpt 0xab" : "+r"(r0) : "r"(r1) : "memory");
    for (;;) {}
}
static void hex(const char *name, uint32_t value) {
    char buf[11] = "00000000\n";
    static const char digits[] = "0123456789abcdef";
    for (unsigned i = 0; i < 8; ++i) buf[i] = digits[(value >> (28 - 4 * i)) & 15];
    out(name); out(buf);
}
__attribute__((noreturn)) void success_report(void) {
    out("PROLOGUE_RETURNED\n"); done(LIMIT == 0 ? 0 : 1);
}
__attribute__((noreturn)) void guard_report(void) {
    out("GUARD_REFUSED_BEFORE_VENDOR_PUSH\n"); done(GUARDED && LIMIT != 0 ? 0 : 1);
}
__attribute__((noreturn)) void fault_report(uint32_t sp, uint32_t limit,
                                           uint32_t cfsr, uint32_t hfsr) {
    out("FAULT_AFTER_VENDOR_PUSH\n"); hex("MSP=", sp); hex("MSPLIM=", limit);
    hex("CFSR=", cfsr); hex("HFSR=", hfsr);
    done(!GUARDED && LIMIT != 0 && (cfsr & 0x00100000) ? 0 : 1);
}
