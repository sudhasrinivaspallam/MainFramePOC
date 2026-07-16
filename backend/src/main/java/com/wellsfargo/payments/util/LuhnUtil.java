package com.wellsfargo.payments.util;

/**
 * Luhn algorithm utility - mirrors PICRD100.cbl card number generation logic.
 * BIN prefix: 400012, sequence padded to 9 digits, check digit via Luhn.
 */
public final class LuhnUtil {

    private static final String BIN_PREFIX = "400012";

    private LuhnUtil() {}

    /**
     * Calculate Luhn check digit for a partial card number.
     * Mirrors PICRD100.cbl GENERATE-CARD-NUMBER paragraph.
     */
    public static int calculateLuhnCheckDigit(String partial) {
        int[] digits = partial.chars().map(c -> c - '0').toArray();
        int total = 0;
        for (int i = digits.length - 1; i >= 0; i--) {
            int d = digits[i];
            if ((digits.length - 1 - i) % 2 == 0) {
                d *= 2;
                if (d > 9) d -= 9;
            }
            total += d;
        }
        return (10 - (total % 10)) % 10;
    }

    /**
     * Generate a 16-digit card number with Luhn validation.
     * BIN prefix (400012) + 9-digit sequence + check digit.
     */
    public static String generateCardNumber(int sequence) {
        String seqStr = String.format("%09d", sequence);
        String partial = BIN_PREFIX + seqStr;
        int checkDigit = calculateLuhnCheckDigit(partial);
        return partial + checkDigit;
    }

    /**
     * Validate a card number using the Luhn algorithm.
     */
    public static boolean validateLuhn(String cardNumber) {
        if (cardNumber == null || cardNumber.length() != 16) return false;
        try {
            Long.parseLong(cardNumber);
        } catch (NumberFormatException e) {
            return false;
        }
        String partial = cardNumber.substring(0, 15);
        int expectedCheck = calculateLuhnCheckDigit(partial);
        int actualCheck = cardNumber.charAt(15) - '0';
        return expectedCheck == actualCheck;
    }
}
