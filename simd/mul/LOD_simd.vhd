library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utility_pkg.all;

entity LOD_simd is
    generic(
        G_N           : integer := 32;
        G_SIMD_FACTOR : integer := 4
    );
    port(
        i_vec       : in  std_logic_vector(G_N - 1 downto 0);
        i_simd_mask : in  std_logic_vector(G_SIMD_FACTOR - 1 downto 0);
        o_k         : out std_logic_vector((G_SIMD_FACTOR * clog2(G_N)) - 1 downto 0); -- according to shifter sizes for ease of use
        o_vld       : out std_logic_vector(G_SIMD_FACTOR - 1 downto 0)
    );
end entity LOD_simd;

-- TODO still have to work out how correct alignement of values is possible

architecture Behavioral of LOD_simd is
    constant C_K_WIDTH_CURRENT : integer := clog2(G_N);
    constant C_K_WIDTH_CHILD   : integer := clog2(G_N / 2);
begin

    -- Base case generation
    gen_base_case : if G_SIMD_FACTOR = 1 generate
        signal s_vld_tmp : std_logic;
    begin
        lod_base : entity work.LOD
            generic map(G_DATA_WIDTH => G_N)
            port map(
                i_x   => i_vec,
                o_K   => o_k, -- Direkt auf o_k, da Längen hier identisch
                o_vld => s_vld_tmp
            );
        o_vld(0) <= s_vld_tmp;
    end generate;

    gen_recursion : if G_SIMD_FACTOR > 1 generate
        -- Korrekte Breite für die Kind-Ports
        constant C_CHILD_K_TOTAL : integer := (G_SIMD_FACTOR / 2) * C_K_WIDTH_CHILD;
        signal   s_k_h, s_k_l     : std_logic_vector(C_CHILD_K_TOTAL - 1 downto 0);
        signal   s_vld_h, s_vld_l : std_logic_vector((G_SIMD_FACTOR / 2) - 1 downto 0);
    begin

        upper_lod : entity work.LOD_simd
            generic map(G_N => G_N / 2, G_SIMD_FACTOR => G_SIMD_FACTOR / 2)
            port map(
                i_vec       => i_vec(G_N - 1 downto G_N / 2),
                i_simd_mask => i_simd_mask(G_SIMD_FACTOR - 1 downto G_SIMD_FACTOR / 2),
                o_k         => s_k_h,
                o_vld       => s_vld_h
            );

        lower_lod : entity work.LOD_simd
            generic map(G_N => G_N / 2, G_SIMD_FACTOR => G_SIMD_FACTOR / 2)
            port map(
                i_vec       => i_vec((G_N / 2) - 1 downto 0),
                i_simd_mask => i_simd_mask((G_SIMD_FACTOR / 2) - 1 downto 0),
                o_k         => s_k_l,
                o_vld       => s_vld_l
            );

        process(i_simd_mask, s_vld_h, s_vld_l, s_k_h, s_k_l)
            variable v_merged_vld : std_logic;
        begin
            v_merged_vld := or_reduce(s_vld_h) or or_reduce(s_vld_l);
            o_k <= (others => '0'); -- Default Safe State

            if i_simd_mask(clog2(G_SIMD_FACTOR) - 1) = '1' then
                o_vld <= s_vld_h & s_vld_l;
                
                for i in 0 to (G_SIMD_FACTOR / 2) - 1 loop
                    -- Low Part Lanes
                    o_k((i+1)*C_K_WIDTH_CURRENT-1 downto i*C_K_WIDTH_CURRENT) <= 
                        std_logic_vector(resize(unsigned(s_k_l((i+1)*C_K_WIDTH_CHILD-1 downto i*C_K_WIDTH_CHILD)), C_K_WIDTH_CURRENT));
                    -- High Part Lanes
                    o_k((i+1 + G_SIMD_FACTOR/2)*C_K_WIDTH_CURRENT-1 downto (i + G_SIMD_FACTOR/2)*C_K_WIDTH_CURRENT) <= 
                        std_logic_vector(resize(unsigned(s_k_h((i+1)*C_K_WIDTH_CHILD-1 downto i*C_K_WIDTH_CHILD)), C_K_WIDTH_CURRENT));
                end loop;
            else
                -- MERGE case
                o_vld             <= (others => '0');
                o_vld(o_vld'high) <= v_merged_vld;

                if or_reduce(s_vld_h) = '1' then
                    o_k(C_K_WIDTH_CURRENT-1 downto 0) <= '0' & s_k_h(C_K_WIDTH_CHILD-1 downto 0);
                else
                    o_k(C_K_WIDTH_CURRENT-1 downto 0) <= '1' & s_k_l(C_K_WIDTH_CHILD-1 downto 0);
                end if;
            end if;
        end process;
    end generate;
end architecture Behavioral;
