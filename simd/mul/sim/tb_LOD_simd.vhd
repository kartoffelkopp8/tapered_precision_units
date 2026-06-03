library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity tb_LOD_simd is
end entity tb_LOD_simd;

architecture Test of tb_LOD_simd is
    constant G_N           : integer := 32;
    constant G_SIMD_FACTOR : integer := 4;
    signal   i_vec, o_vec  : std_logic_vector(G_N - 1 downto 0);
    signal   mask          : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
    signal   o_k           : std_logic_vector((G_SIMD_FACTOR * clog2(G_N)) - 1 downto 0);
    signal   o_vld         : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
begin
    dut : entity work.LOD_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_vec       => i_vec,
            i_simd_mask => mask,
            o_k         => o_k,
            o_vld       => o_vld
        );

    trigger : process is
    begin
        i_vec <= x"00001000";
        mask  <= "1000";
        wait for 20 ns;
        assert o_vld = "1000" report "error total summmary";

        wait for 10 ns;

        i_vec <= x"01000010";
        mask  <= "1010";
        wait for 20 ns;
        assert o_vld = "1010" report "error first 1010 mask";

        wait for 10 ns;

        i_vec <= x"01000000";
        mask  <= "1010";
        wait for 20 ns;
        assert o_vld = "1000" report "error second 1010 mask";

        i_vec <= x"01010101";
        mask <= "1111";
        wait for 20 ns;
        assert o_vld = "1111" report "error 1111 mask";
        

        wait for 10 ns;
        std.env.stop;
    end process;
end architecture Test;
