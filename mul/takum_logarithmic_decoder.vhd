library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity takum_logarithmic_decoder is
    generic(
        G_N : integer := 32
    );
    port(
        i_takum : in  std_logic_vector(G_N - 1 downto 0);
        o_l     : out std_logic_vector(G_N + 3 downto 0)
    );
end entity takum_logarithmic_decoder;

architecture Behavioral of takum_logarithmic_decoder is
    signal s_c    : std_logic_vector(8 downto 0);
    signal s_mant : std_logic_vector(G_N - 5 - 1 downto 0);
begin
    predecoder : entity work.takum_predecoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum => i_takum,
            o_c     => s_c,
            o_mant  => s_mant
        );

    o_l <= std_logic_vector(signed(s_c & s_mant)) when i_takum(G_N - 1) = '0' else
           std_logic_vector(-signed(s_c & s_mant));

end architecture Behavioral;
