library ieee;
library work;

use ieee.STD_LOGIC_1164.ALL;
use ieee.NUMERIC_STD.ALL;
use ieee.math_real.all;

use work.utility_pkg.all;

entity posit_right_shift_simd is
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
end posit_right_shift_simd;

architecture Behavioral of posit_right_shift_simd is

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
    -- Shifter Stages (Rechts-Shift Modifikation)
    gen_stages: for k in 0 to C_LOG_N-1 generate
        constant C_SHIFT_DISTANCE : integer := 2**k;
    begin
        process(s_stage(k), s_shift_amts, i_mode)
            variable v_current_lane_width : integer;
            variable v_active_shift_bit   : std_logic;
            variable v_lane_idx           : integer;
        begin
            -- Breite basierend auf i_mode bestimmen
            v_current_lane_width := G_N / (2**to_integer(unsigned(i_mode)));

            for i in 0 to G_N-1 loop
                -- Bestimmung des aktiven Shift-Bits für diese Lane
                v_lane_idx := i / v_current_lane_width;
                v_active_shift_bit := s_shift_amts(v_lane_idx * (v_current_lane_width / C_BASE_WIDTH))(k);

                if v_active_shift_bit = '1' then
                    -- Wenn wir über das Ende des gesamten Vektors hinausschauen:
                    if (i + C_SHIFT_DISTANCE >= G_N) then
                        s_stage(k+1)(i) <= '0';
                    else
                        -- SIMD BOUNDARY CHECK: 
                        -- Prüfen, ob das Quell-Bit (i + dist) noch in der gleichen Lane liegt
                        if (i / v_current_lane_width) /= ((i + C_SHIFT_DISTANCE) / v_current_lane_width) then
                            s_stage(k+1)(i) <= '0'; -- Bit würde aus einer anderen Lane kommen -> mit 0 füllen
                        else
                            s_stage(k+1)(i) <= s_stage(k)(i + C_SHIFT_DISTANCE); -- Korrekter Rechts-Shift
                        end if;
                    end if;
                else
                    -- Wenn das Bit k im Shift-Amount 0 ist: Wert einfach durchreichen
                    s_stage(k+1)(i) <= s_stage(k)(i);
                end if;
            end loop;
        end process;
    end generate;

    o_result <= s_stage(C_LOG_N);
    
end Behavioral;
