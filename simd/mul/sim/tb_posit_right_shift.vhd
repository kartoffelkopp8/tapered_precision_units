library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity tb_posit_right_shift is
end entity tb_posit_right_shift;

architecture Test of tb_posit_right_shift is
    constant CYCLE : time := 10 ns;

    constant G_N           : integer := 32;
    constant G_SIMD_FACTOR : integer := 4;

    signal i_data       : std_logic_vector(G_N - 1 downto 0);
    signal i_shift_amts : std_logic_vector((G_SIMD_FACTOR * clog2(G_N)) - 1 downto 0); -- expected inputs in format: per lane gibve one number as big as clog2(G_N), if less numbers always left aligned
    signal i_mode       : std_logic_vector(integer(clog2(G_SIMD_FACTOR)) - 1 downto 0);
    signal o_result     : std_logic_vector(G_N - 1 downto 0);
begin

    dut : entity work.posit_right_shift_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_data       => i_data,
            i_shift_amts => i_shift_amts,
            i_mode       => i_mode,
            o_result     => o_result
        );

    stimuli : process
    begin
        i_data       <= x"00000001";
        i_shift_amts <= "00000000000000000000";
        i_mode       <= "00";
        assert o_result = i_data report "Test 1 error: no shift failure";
        wait for CYCLE;

        i_data       <= x"00000003";
        i_shift_amts <= "00000000000000000010";
        i_mode       <= "00";
        assert o_result = x"00000001" report "Test 2 error: 1x32 small shift failure";

        i_data       <= x"80000000";
        i_shift_amts <= "00000000000000011111";
        i_mode       <= "00";
        assert o_result = x"00000001" report "Test 3 error: big shift 1x32 bit vector failure";

        wait for CYCLE;

        i_data       <= x"00020002";
        i_shift_amts <= "00000000000000000001";
        i_mode       <= "01";
        assert o_result = x"00020001" report "Test 4 error: small shift 2x16 bit vector failure";

        wait for CYCLE;

        i_mode       <= "10";
        i_data       <= x"01010404";
        i_shift_amts <= "01000" & "00000" & "00010" & "00010";
        assert o_result = x"00010101" report "Test 5 error: small shift 4x8 bit vector failure";

        wait for CYCLE;
        wait for 2*CYCLE;

        std.env.stop;
    end process;
end architecture Test;
