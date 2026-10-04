package ru.hundrik.portfolio;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class GreetingTest {
    @Test void defaultsForNull() { assertEquals("Hello, DevOps!", Greeting.message(null)); }
    @Test void defaultsForBlank() { assertEquals("Hello, DevOps!", Greeting.message("  ")); }
    @Test void trimsName() { assertEquals("Hello, Hundrik!", Greeting.message(" Hundrik ")); }
    @Test void rejectsOversizedName() { assertThrows(IllegalArgumentException.class, () -> Greeting.message("x".repeat(81))); }
}
