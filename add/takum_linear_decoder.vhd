library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity takum_linear_decoder is
    generic(
        G_N : integer := 32
    );
    port(
        i_takum    : in  std_logic_vector(G_N - 1 downto 0);
        o_exponent : out std_logic_vector(8 downto 0);
        o_fraction : out std_logic_vector(G_N - 5 - 1 + 2 downto 0) -- mantissa width + 2 for 10 if S=1 or 01 if sign = 0
    );
end entity takum_linear_decoder;

architecture RTL of takum_linear_decoder is
    signal s_sign : std_logic;

    signal s_c             : std_logic_vector(8 downto 0);
    signal s_mant          : std_logic_vector(G_N - 5 - 1 downto 0);
    signal s_fraction_sign : std_logic_vector(1 downto 0);
begin
    s_sign <= i_takum(G_N - 1);

    predecoder : entity work.takum_predecoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum => i_takum,
            o_c     => s_c,
            o_mant  => s_mant
        );

    s_fraction_sign <= "10" when s_sign = '1' else "01";

    o_exponent <= cond_invert(s_c, s_sign); -- follows formula from paper, if s=1 => (-1)^S * (s+c) = -c-1 = not(s) else c
    o_fraction <= s_fraction_sign & s_mant;
end architecture RTL;
