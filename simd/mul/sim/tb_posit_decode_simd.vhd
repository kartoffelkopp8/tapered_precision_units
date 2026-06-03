library ieee;
library work;

use ieee.std_logic_1164.all;
use work.utility_pkg.all;

entity tb_posit_decode_simd is
end entity;

architecture Test of tb_posit_decode_simd is
    constant C_CLK : time := 10 ns;

    signal val : std_logic_vector(31 downto 0);
    signal mask : std_logic_vector(3 downto 0);
    signal exp : std_logic_vector(2 downto 0) := (others => '0');
    signal o_rc : std_logic_vector(3 downto 0);
    signal o_regime :  std_logic_vector(32- 1 downto 0);
    signal o_exp : std_logic_vector((4 * 4) - 1 downto 0);
    signal o_mant : std_logic_vector(27 downto 0);
    signal simd : std_logic_vector(clog2(3)-1 downto 0);
begin
    dut : entity work.posit_decode_simd
        generic map(
            G_N           => 32,
            G_MAX_ES      => 4,
            G_SIMD_FACTOR => 4
        )
        port map(
            i_val       => val,
            i_simd_mode => simd,
            i_simd_mask => mask,
            i_dyn_exp   => exp,
            o_rc        => o_rc,
            o_regime    => o_regime,
            o_exp       => o_exp,
            o_mant      => o_mant
        );
    

        stimulus : process is
        begin
            val <= x"1ACC0000";
            simd <= "10";
            mask <= "1111";
            exp <= "100";

            wait for C_CLK;
           
            wait for 2* C_CLK;

            std.env.stop;
        end process stimulus;
        
end architecture Test;
