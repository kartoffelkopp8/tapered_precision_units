library ieee;
library work;

use ieee.STD_LOGIC_1164.ALL;
use ieee.NUMERIC_STD.ALL;
use ieee.math_real.all;

use work.utility_pkg.all;

entity posit_left_shift_simd is
    generic(
        G_N          : integer := 32;
        G_SIMD_FACTOR : integer := 4
    );
    port(
        i_data      : in std_logic_vector(G_N-1 downto 0);
        -- To simplify implementation use max necessary bits for shifting G_N Bits for all modes.
        i_shift_amts  : in  std_logic_vector((G_SIMD_FACTOR * clog2(G_N)) - 1 downto 0);     -- expected inputs in format: per lane gibve one number as big as clog2(G_N), if less numbers always left aligned
        i_mode        : in  std_logic_vector(integer(ceil(log2(real(G_SIMD_FACTOR))))-1 downto 0);
        o_result      : out std_logic_vector(G_N-1 downto 0)
    );
end posit_left_shift_simd;

architecture Behavioral of posit_left_shift_simd is

    constant C_LOG_N    : integer := integer(ceil(log2(real(G_N))));
    constant C_BASE_WIDTH   : integer := G_N / G_SIMD_FACTOR;

    type T_SHIFT_ARRAY is array (0 to G_SIMD_FACTOR-1) of std_logic_vector(C_LOG_N-1 downto 0);
    type T_STAGE_DATA  is array (0 to C_LOG_N) of std_logic_vector(G_N-1 downto 0);

    signal s_shift_amts : T_SHIFT_ARRAY;
    signal s_stage      : T_STAGE_DATA;

begin
    -- Unpack input shift amounts into array
    gen_unpack: for i in 0 to G_SIMD_FACTOR-1 generate
        s_shift_amts(i) <= i_shift_amts((i+1)*C_LOG_N-1 downto i*C_LOG_N);
    end generate;

    s_stage(0) <= i_data;

    -- Shifter Stages
    gen_stages: for k in 0 to C_LOG_N-1 generate
        constant C_SHIFT_DISTANCE : integer := 2**k;
    begin
        process(s_stage(k), s_shift_amts, i_mode)
            variable v_current_lane_width : integer;
            variable v_active_shift_bit   : std_logic;
            variable v_lane_idx           : integer;
        begin
            -- Determine width based on mode (8, 16, 32, etc)
            v_current_lane_width := G_N / (2**to_integer(unsigned(i_mode)));

            for i in 0 to G_N-1 loop
                -- Which lane does this bit belong to?
                v_lane_idx := i / v_current_lane_width;
                
                -- All segments in a larger lane (e.g. 16-bit)  must use the shift amount of the "master" segment (the LSB segment).
                -- Calculate the index of the master segment:
                v_active_shift_bit := s_shift_amts((i / v_current_lane_width) * (v_current_lane_width / C_BASE_WIDTH))(k);

                if v_active_shift_bit = '1' then
                    if (i < C_SHIFT_DISTANCE) then
                        s_stage(k+1)(i) <= '0';
                    else
                        -- BOUNDARY CHECK: Block the shift if the source bit is outside the current lane.
                        if (i / v_current_lane_width) /= ((i - C_SHIFT_DISTANCE) / v_current_lane_width) then
                            s_stage(k+1)(i) <= '0';
                        else
                            s_stage(k+1)(i) <= s_stage(k)(i - C_SHIFT_DISTANCE);
                        end if;
                    end if;
                else
                    s_stage(k+1)(i) <= s_stage(k)(i);
                end if;
            end loop;
        end process;
    end generate;

    o_result <= s_stage(C_LOG_N);
    
end Behavioral;
