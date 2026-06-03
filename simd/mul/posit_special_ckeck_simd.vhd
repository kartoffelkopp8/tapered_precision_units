library ieee;

use ieee.std_logic_1164.all;

entity posit_special_ckeck_simd is
    generic(
        G_N           : integer := 32;
        G_SIMD_FACTOR : integer := 4
    );
    port(
        i_simd_mask : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        i_sign_0    : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        i_sign_1    : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        i_vec_0     : in  std_logic_vector(G_N - 1 downto 0);
        i_vec_1     : in  std_logic_vector(G_N - 1 downto 0);
        o_is_nar    : out std_logic_vector(G_SIMD_FACTOR - 1 downto 0)
    );
end entity posit_special_ckeck_simd;

architecture Structural of posit_special_ckeck_simd is
    signal s_is_nar_0, s_is_nar_1 : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
begin
    check_0 : entity work.special_check_vector_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_simd_mask => i_simd_mask,
            i_sign      => i_sign_0,
            i_vec       => i_vec_0,
            o_is_nar    => s_is_nar_0
        );

    check_1 : entity work.special_check_vector_simd
        generic map(
            G_N           => G_N,
            G_SIMD_FACTOR => G_SIMD_FACTOR
        )
        port map(
            i_simd_mask => i_simd_mask,
            i_sign      => i_sign_1,
            i_vec       => i_vec_1,
            o_is_nar    => s_is_nar_1
        );

    gen_total : for i in 0 to G_SIMD_FACTOR - 1 generate 
        o_is_nar(i) <= s_is_nar_0(i) or s_is_nar_1(i);
    end generate;

end architecture Structural;
