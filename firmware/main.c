// Prime number display: show all primes < 256 on LEDs sequentially.
// Each prime value (0-255) is output on the lower 8 LEDs (active-low at top-level).
// After finishing (last prime 251), pause briefly then restart.

#define GPIO_BASE 0x80000000

// External assembly delay function (defined in delay.S)
extern void delay_cycles(void);

// Simple trial-division primality test for 0..255.
// Primality test without using *, / or % to avoid libgcc helpers.
// Naive: try all divisors 2..n-1; for each divisor perform repeated subtraction
// to see if it divides evenly. Good enough for n < 256.
static int is_prime(unsigned int n) {
    if (n < 2) return 0;
    for (unsigned int d = 2; d < n; ++d) {
        unsigned int t = n;
        while (t >= d) {
            t -= d;            // emulate modulo by repeated subtraction
        }
        if (t == 0) {          // divisible
            return 0;
        }
    }
    return 1;
}

int main(void) {
    volatile unsigned int *gpio = (volatile unsigned int *)GPIO_BASE;

    while (1) {
        for (unsigned int n = 2; n < 256; ++n) {
            if (is_prime(n)) {
                *gpio = n;      // show prime value (binary) on LEDs
                delay_cycles(); // visible delay
            }
        }

        // Gap before restarting sequence
        *gpio = 0;              // all LEDs off (active-low inversion means all on if inverted; adjust if needed)
        delay_cycles();
        delay_cycles();         // a bit longer pause
    }

    return 0; // never reached
}
