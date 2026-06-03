library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_twos_complement is
end entity;

architecture sim of tb_twos_complement is
    -- Konstanten für die Simulation
    constant C_N           : integer := 32;
    constant C_SIMD_FACTOR : integer := 4;
    
    -- Signale zur Ansteuerung
    signal i_simd_mask : std_logic_vector(C_SIMD_FACTOR - 1 downto 0) := (others => '0');
    signal i_sign      : std_logic_vector(C_SIMD_FACTOR - 1 downto 0) := (others => '0');
    signal i_vec       : std_logic_vector(C_N - 1 downto 0) := (others => '0');
    signal o_vec       : std_logic_vector(C_N - 1 downto 0);

begin

    -- Device Under Test (DUT)
    dut : entity work.twos_complement_simd
        generic map (
            G_N           => C_N,
            G_SIMD_FACTOR => C_SIMD_FACTOR
        )
        port map (
            i_simd_mask => i_simd_mask,
            i_sign      => i_sign,
            i_vec       => i_vec,
            o_vec       => o_vec
        );

    -- Stimuli Process
    process
    begin
        report "Start";

        -----------------------------------------------------------------------
        -- TEST 1: 1x 32-Bit Vektor (Ganze Zahl invertieren)
        -----------------------------------------------------------------------
        i_simd_mask <= "1000"; 
        i_sign      <= "1000"; -- Wir wollen das Vorzeichen von oben nutzen
        i_vec       <= x"00000001"; -- Wert 5
        wait for 10 ns;
        assert o_vec = x"FFFFFFFF" report "Test 1 error";
        -- Erwartet: Zweierkomplement von 5 ist ffffffb (-5)
        
        -----------------------------------------------------------------------
        -- TEST 2: 2x 16-Bit Vektoren
        -----------------------------------------------------------------------
  
        i_simd_mask <= "1010";
        i_sign      <= "1010"; 
        i_vec       <= x"0001_0001"; 
        wait for 10 ns;
        assert o_vec = x"FFFFFFFF" report "Test 2.1 error";
      
        i_simd_mask <= "1010";
        i_sign      <= "1000"; 
        i_vec       <= x"01010101"; 
        wait for 10 ns;
        assert o_vec = x"FEFF0101" report "Test 2.2 error";
        -----------------------------------------------------------------------
        -- TEST 3: 4x 8-Bit Vektoren
        -----------------------------------------------------------------------

        i_simd_mask <= "1111";
        i_sign      <= "1111";
        i_vec       <= x"01010101";
        wait for 10 ns;
        assert o_vec = x"FFFFFFFF"; 

        report "Simulation beendet.";
        std.env.stop;
    end process;

end architecture;