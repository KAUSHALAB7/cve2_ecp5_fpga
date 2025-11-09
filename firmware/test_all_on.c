// Simple test: Turn ALL LEDs ON
// GPIO base address: 0x80000000

#define GPIO_BASE 0x80000000
#define GPIO_REG (*(volatile unsigned int *)GPIO_BASE)

int main(void) {
    // Turn on ALL LEDs (0xFF = all 8 LEDs)
    // Active-LOW hardware will invert this
    while (1) {
        GPIO_REG = 0xFF;  // All LEDs on
    }
    
    return 0;
}
