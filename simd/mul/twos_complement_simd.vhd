library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utility_pkg.all;

-- idea : partition the input into "lanes" use G_SIMD_FACTOR stoppers for carries and decide with a simd decoder which carries are propagated
-- entity takes the twos_complement of simd posit _vector dependent on sign input vector
entity twos_complement_simd is
    generic(
        G_N           : integer := 32;  -- total bitwidth of input and output vectors
        G_SIMD_FACTOR : integer := 4    -- maximal number of parts, power of 2
    );
    port(
        i_simd_mask : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        i_sign      : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        i_vec       : in  std_logic_vector(G_N - 1 downto 0);
        o_vec       : out std_logic_vector(G_N - 1 downto 0)
    );
end entity;

architecture Behavioural of twos_complement_simd is
    signal s_eff_sign    : std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
    signal s_inverted    : std_logic_vector(G_N - 1 downto 0);
    signal s_mask_eff : std_logic_vector(G_SIMD_FACTOR downto 0);
    signal s_carries     : std_logic_vector(G_SIMD_FACTOR downto 0);
    
    constant C_CHUNK_WIDTH : integer := G_N / G_SIMD_FACTOR;
begin

    s_eff_sign(G_SIMD_FACTOR - 1) <= i_sign(G_SIMD_FACTOR - 1);
    gen_sign_chain : for i in G_SIMD_FACTOR - 2 downto 0 generate
        s_eff_sign(i) <= i_sign(i) when i_simd_mask(i) = '1' else s_eff_sign(i + 1);
    end generate;

    gen_xor_bits : for i in 0 to G_N - 1 generate
        s_inverted(i) <= i_vec(i) xor s_eff_sign(i / C_CHUNK_WIDTH);
    end generate;


    s_carries(0) <= s_eff_sign(0);
    s_mask_eff <= i_simd_mask & "1";

    gen_add_chunks : for i in 0 to G_SIMD_FACTOR - 1 generate
        signal s_chunk_res : unsigned(C_CHUNK_WIDTH downto 0); -- addition, higehst bvit is overflow bit for overflow gating
        constant C_START   : integer := i * C_CHUNK_WIDTH;
    begin
       
        s_chunk_res <= unsigned('0' & s_inverted(C_START + C_CHUNK_WIDTH - 1 downto C_START)) + unsigned'("" & s_carries(i));

        o_vec(C_START + C_CHUNK_WIDTH - 1 downto C_START) <= std_logic_vector(s_chunk_res(C_CHUNK_WIDTH - 1 downto 0));

        gen_mux : if i < G_SIMD_FACTOR - 1 generate
            s_carries(i + 1) <= s_chunk_res(C_CHUNK_WIDTH) when s_mask_eff(i+1) = '0' else 
                                s_eff_sign(i + 1);
        end generate;
    end generate;
end architecture;
