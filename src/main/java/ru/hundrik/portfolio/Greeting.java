package ru.hundrik.portfolio;

public final class Greeting {
    private Greeting() {}
    public static String message(String name) {
        String cleaned = name == null ? "" : name.strip();
        if (cleaned.isEmpty()) cleaned = "DevOps";
        if (cleaned.length() > 80) throw new IllegalArgumentException("Name must be at most 80 characters");
        return "Hello, " + cleaned + "!";
    }
}
