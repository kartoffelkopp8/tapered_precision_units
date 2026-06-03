library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utility_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inverter_simd is
    generic(
        G_N           : integer := 32;  -- total bitwidth of input and output vectors
        G_SIMD_FACTOR : integer := 4    -- maximal number of parts, power of 2
    );
    port(
        i_simd_mask : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        i_invert    : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0); -- inverter vector (what to invert)
        i_vec       : in  std_logic_vector(G_N - 1 downto 0);
        o_vec       : out std_logic_vector(G_N - 1 downto 0)
    );
end entity inverter_simd;

architecture Behavioral of inverter_simd is
    signal s_eff_sign    : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
    signal s_inverted    : std_logic_vector(G_N - 1 downto 0);    

    constant C_CHUNK_WIDTH : integer := G_N / G_SIMD_FACTOR;
begin
    s_eff_sign(G_SIMD_FACTOR - 1) <= i_invert(G_SIMD_FACTOR - 1);
    gen_sign_chain : for i in G_SIMD_FACTOR - 2 downto 0 generate
        s_eff_sign(i) <= i_invert(i) when i_simd_mask(i) = '1' else s_eff_sign(i + 1);
    end generate;

    gen_xor_bits : for i in 0 to G_N - 1 generate
        s_inverted(i) <= i_vec(i) xor s_eff_sign(i / C_CHUNK_WIDTH);
    end generate;

    o_vec <= s_inverted;
end architecture Behavioral;
