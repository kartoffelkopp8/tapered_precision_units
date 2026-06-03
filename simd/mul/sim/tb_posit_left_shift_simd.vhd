library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity tb_posit_left_shift_simd is
end tb_posit_left_shift_simd;

architecture Behavioral of tb_posit_left_shift_simd is

    constant C_CLK_PERIOD : time := 10 ns;

    constant G_N           : integer := 32;
    constant G_SIMD_FACTOR : integer := 4;

    signal s_clk : std_logic := '0';
    
    signal i_data        : std_logic_vector(G_N-1 downto 0);
    signal i_shift_amts  : std_logic_vector((G_SIMD_FACTOR * integer(ceil(log2(real(G_N))))) - 1 downto 0);
    signal i_mode        : std_logic_vector(integer(ceil(log2(real(G_SIMD_FACTOR))))-1 downto 0);
    signal o_result      : std_logic_vector(G_N-1 downto 0);

begin

    s_clk <= not s_clk after C_CLK_PERIOD/2;

    uut: entity work.posit_left_shift_simd
    generic map (
        G_N           => G_N,
        G_SIMD_FACTOR => G_SIMD_FACTOR
    )
    port map (
        i_data        => i_data,
        i_shift_amts  => i_shift_amts,
        i_mode        => i_mode,
        o_result      => o_result
    );
    
    process
    begin
        wait until rising_edge(s_clk);
        
        i_data <= x"00000001";
        i_shift_amts <= "00000000000000000000";
        i_mode <= "00";
        
        wait until rising_edge(s_clk);
        
        i_data <= x"00000001";
        i_shift_amts <= "00000000000000000010";
        i_mode <= "00";
        
        i_data <= x"00000001";
        i_shift_amts <= "00000000000000011111";
        i_mode <= "00";
        
        wait until rising_edge(s_clk);
        
        wait until rising_edge(s_clk);
        
        i_data <= x"00010001";
        i_shift_amts <= "00000000000000000010";
        i_mode <= "01";
        
        wait until rising_edge(s_clk);
        
        i_data <= x"01010101";
        i_shift_amts <= "01000000000000100010";
        i_mode <= "10";
        
        wait until rising_edge(s_clk);
        
        i_data <= x"010101FF";
        i_shift_amts <= "01000000000000100010";
        i_mode <= "10";
        
        wait until rising_edge(s_clk);
        std.env.stop;
    end process;    


end Behavioral;
