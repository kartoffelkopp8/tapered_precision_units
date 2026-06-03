library ieee;
library work;

use ieee.std_logic_1164.all;
use work.utility_pkg.all;

-- entity for checking if parts of the simd vector are NaR
entity special_check_vector_simd is
    generic(
        G_N           : integer := 32;
        G_SIMD_FACTOR : integer := 4
    );
    port(
        i_simd_mask : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        i_sign : in std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        i_vec       : in  std_logic_vector(G_N - 1 downto 0);
        o_is_nar    : out std_logic_vector(G_SIMD_FACTOR - 1 downto 0)
    );
end entity special_check_vector_simd;

-- idea: or reduce smalles parts, then selectivly or with the adges of the lanes (the signs)
architecture Behavioural of special_check_vector_simd is
    constant C_CHUNK_SIZE : integer := G_N / G_SIMD_FACTOR;

    signal s_reduced     : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
begin

    -- process or reduces with simd in mind
    process(i_vec, i_simd_mask)
        variable v_start      : integer := 0;
        variable v_msb        : integer := 0;
        variable v_chunk_body : std_logic;
    begin
        s_reduced <= (others => '0');

        for i in 0 to G_SIMD_FACTOR - 1 loop
            v_start := i * C_CHUNK_SIZE;
            v_msb   := v_start + C_CHUNK_SIZE - 1;
            v_chunk_body := '0';

            v_chunk_body := or_reduce(i_vec(v_msb-1 downto v_start));

            if i_simd_mask(i) = '0' then
                s_reduced(i) <= v_chunk_body or i_vec(v_msb);
            else
                s_reduced(i) <= v_chunk_body;
            end if;
        end loop;
    end process;

    -- generate nar representation
    is_nar : process(i_sign, i_simd_mask, s_reduced) 
        variable v_unified_mask_sign : std_logic_vector(G_SIMD_FACTOR-1 downto 0);
    begin 
        v_unified_mask_sign := i_simd_mask and i_sign;
        
        for i in 0 to G_SIMD_FACTOR-1 loop 
            if s_reduced(i) = '0' and v_unified_mask_sign(i) = '1' then 
                o_is_nar(i) <= '1';
            else  
                o_is_nar(i) <= '0';
            end if;
        end loop;
    end process;
end architecture Behavioural;
