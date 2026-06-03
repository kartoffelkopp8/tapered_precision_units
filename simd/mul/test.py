import math

def is_power_of_two(n):
    """Prüft, ob n eine Zweierpotenz ist (1, 2, 4, 8, ...)"""
    return n > 0 and (n & (n - 1)) == 0

def check_inequality(G_N, verbose=True):
    """
    Prüft für alle Zweierpotenzen x (1 <= x <= G_N) und alle ES (0 <= ES <= G_N),
    ob gilt: G_N - ES - 2 > x * (G_N / x - ES - 2)
    """
    violations = []
    
    # Alle Zweierpotenzen bis G_N
    powers_of_two = [2**i for i in range(int(math.log2(G_N)) + 1)]
    
    for x in powers_of_two:
        for ES in range(G_N + 1):  # ES von 0 bis G_N
            # Berechne linke Seite: G_N - ES - 2
            left = G_N - ES - 2
            
            # Berechne rechte Seite: x * (G_N/x - ES - 2)
            # Achtung: G_N/x ist möglicherweise nicht ganzzahlig
            right = x * (G_N / x - ES - 2)
            
            # Prüfe die Ungleichung: left > right
            # Verwende kleine Toleranz wegen float-Rundungsfehlern
            if not (left > right - 1e-10):
                violations.append((x, ES, left, right))
                if verbose:
                    print(f"❌ Verletzung bei x={x}, ES={ES}: "
                          f"{left:.6f} > {right:.6f} ist FALSCH")
    
    if not violations:
        print(f"✅ Für alle Zweierpotenzen x und alle ES (0..{G_N}) gilt die Ungleichung!")
        return True
    else:
        print(f"❌ {len(violations)} Verletzungen gefunden.")
        return False

def simplify_inequality(G_N, x, ES):
    """
    Vereinfachte Darstellung der Ungleichung für ein konkretes x und ES
    """
    left = G_N - ES - 2
    # G_N/x * x = G_N (wenn G_N durch x teilbar, sonst float)
    right = G_N - x * ES - 2 * x
    return left, right

def analyze_for_powers_of_two(G_N):
    """
    Detaillierte Analyse für alle Zweierpotenzen
    """
    print(f"\n{'='*60}")
    print(f"Analyse für G_N = {G_N}")
    print(f"{'='*60}")
    
    powers_of_two = [2**i for i in range(int(math.log2(G_N)) + 1)]
    
    # Zuerst der vereinfachte Ausdruck:
    print("\n📐 Vereinfachung der Ungleichung:")
    print("   G_N - ES - 2 > G_N - x*ES - 2x")
    print("   ⇔ -ES - 2 > -x*ES - 2x")
    print("   ⇔ x*ES - ES + 2x - 2 > 0")
    print("   ⇔ ES*(x - 1) + 2*(x - 1) > 0")
    print("   ⇔ (x - 1)*(ES + 2) > 0")
    print("\n   Da ES + 2 > 0 für ES >= 0, gilt:")
    print("   Die Ungleichung ist genau dann wahr, wenn x > 1 (also x >= 2)")
    print("   Für x = 1: (0)*(ES+2) > 0 → 0 > 0 → FALSCH")
    print("\n✨ Ergebnis: Für x >= 2 gilt die Ungleichung für ALLE ES!")
    
    print("\n📊 Überprüfung mit konkreten Werten:")
    for x in powers_of_two:
        test_es = [0, G_N // 4, G_N // 2, G_N - 1, G_N]
        for ES in test_es:
            if ES <= G_N:
                left = G_N - ES - 2
                right = x * (G_N / x - ES - 2)
                # Vereinfacht:
                right_simple = G_N - x*ES - 2*x
                status = "✓" if left > right_simple - 1e-10 else "✗"
                print(f"  x={x:3d}, ES={ES:3d}: {left:6.1f} > {right_simple:6.1f} → {status}")

def main():
    # Test für verschiedene G_N
    test_values = [4, 8, 16, 32, 64, 128, 256]
    
    for G_N in test_values:
        analyze_for_powers_of_two(G_N)
        print()
    
    # Detaillierter Check für einen spezifischen Wert
    print("\n" + "="*60)
    print("Detaillierte Überprüfung für G_N = 100")
    print("="*60)
    check_inequality(1024, verbose=True)

if __name__ == "__main__":
    main()
