#include <stdio.h>
#include <stdint.h>
#include <takum.h>

// compile with cc -o gen_refdata gen_refdata_takum.c \
  -L/home/felix/Projects/VLSI/praktikum/tools/libtakum \
  -ltakum \
  -lm \
  -Wl,-rpath,/home/felix/Projects/VLSI/praktikum/tools/libtakum

int main() {
    // Erstelle die Testdatei
    FILE *f = fopen("testvectors.txt", "w");
    if (f == NULL) {
        printf("Fehler beim Oeffnen der Datei!\n");
        return 1;
    }

    // Wir nutzen unsigned int für die Schleifen, um alle 256 Muster sauber zu durchlaufen
    for (int i = 0; i < 256; i++) {
        for (int j = 0; j < 256; j++) {
            // Umwandlung in den takum8 Typ (int8_t)
            takum_log8 op_a = (takum_log8)i;
            takum_log8 op_b = (takum_log8)j;

            // Berechnung mit der Library
            takum_log8 result = takum_log8_multiplication(op_a, op_b);

            // Ausgabe als Hex-Bitmuster: 
            // Wir casten auf uint8_t, damit Werte wie 0xFF nicht als ffffffff gedruckt werden.
            fprintf(f, "%02x %02x %02x\n", (uint8_t)op_a, (uint8_t)op_b, (uint8_t)result);
        }
    }

    takum_log8 opa = 0xB2;
    takum_log8 opb = 0xBE;

    // Nutzen Sie takum_log8_multiplication passend zum Datentyp
    takum_log8 res = takum_log8_multiplication(opa, opb);

    // Ausgabe des Ergebnis-Bitmusters als Hexadezimalwert
    printf("%02x\n", (uint8_t)res);

    printf("Done\n");
    return 0;
}