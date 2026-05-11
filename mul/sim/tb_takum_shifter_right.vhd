library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_takum_shifter_right is
end entity tb_takum_shifter_right;

architecture Test of tb_takum_shifter_right is
    constant G_N : integer := 16;
    constant G_MAX_SHIFT : integer := 3;
    signal i_vec : std_logic_vector(G_N-1 downto 0);
    signal i_fill_bit : std_logic;
    signal i_shift_amount  : std_logic_vector(G_MAX_SHIFT-1 downto 0);
    signal o_vec : std_logic_vector(G_N-1 downto 0);
begin
    dut : entity work.takum_shift_right
        generic map(
            G_N         => G_N,
            G_MAX_SHIFT => G_MAX_SHIFT
        )
        port map(
            i_vec          => i_vec,
            i_fill_bit     => i_fill_bit,
            i_shift_amount => i_shift_amount,
            o_vec          => o_vec
        );
    
    stimulus : process 
    begin 
        i_vec          <= x"AAAA"; -- 10101010...
        i_fill_bit     <= '1';
        i_shift_amount <= "000";
        wait for 10 ns;
        assert o_vec = x"AAAA" report "Fehler: Shift 0 fehlgeschlagen" severity error;

        i_shift_amount <= "001"; 
        wait for 10 ns;
        assert o_vec = x"D555" report "Fehler: Shift 1 (fill 1) fehlgeschlagen" severity error;

        i_fill_bit     <= '0';
        i_shift_amount <= "100"; 
        wait for 10 ns;
        assert o_vec = x"0AAA" report "Fehler: Shift 4 (fill 0) fehlgeschlagen" severity error;

        i_fill_bit     <= '1';
        i_shift_amount <= "111"; 
        wait for 10 ns;
        assert o_vec = x"FF55" report "Fehler: Max Shift 7 fehlgeschlagen" severity error;
       
        wait for 20 ns;
        std.env.stop;
    end process;
end architecture Test;

