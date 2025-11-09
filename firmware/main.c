// Water flow LED pattern
// Creates a flowing effect like water moving across the 8 LEDs

#define GPIO_BASE 0x80000000

// External assembly delay function (defined in delay.S)
extern void delay_cycles(void);

int main(void) {
    volatile unsigned int *gpio = (volatile unsigned int *)GPIO_BASE;
    unsigned int pattern;
    unsigned int i;

    while (1) {
        // Flow pattern from right to left (bit 0 to bit 7)
        for (i = 0; i < 8; i++) {
            // Create a 3-LED wide "wave" for water effect
            pattern = 0x07 << i;  // 3 consecutive LEDs (0b00000111)
            pattern &= 0xFF;       // Keep only 8 bits
            *gpio = pattern;
            delay_cycles();
        }
        
        // Flow pattern from left to right (bit 7 to bit 0)
        for (i = 0; i < 8; i++) {
            // Create a 3-LED wide "wave" for water effect
            pattern = 0xE0 >> i;  // 3 consecutive LEDs (0b11100000)
            pattern &= 0xFF;       // Keep only 8 bits
            *gpio = pattern;
            delay_cycles();
        }
    }

    return 0; // never reached
}
