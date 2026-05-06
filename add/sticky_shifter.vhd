library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.pkg_utility.all;

entity sticky_shifter is
    generic(
        C_DATA_WIDTH : integer := 26
    );
    port(
        i_number      : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        i_shift_count : in  std_logic_vector(integer(ceil(log2(real(C_DATA_WIDTH)))) - 1 downto 0);
        o_result      : out std_logic_vector(C_DATA_WIDTH downto 0)
    );
end entity;

-- Sticky OR Chain integrated in shifter (more efficient for ASIC)
-- Pushes Zeros into the vector
architecture open_rtl of sticky_shifter is
    constant S : integer := integer(ceil(log2(real(C_DATA_WIDTH))));

    type   stage_array   is array (0 to S) of std_logic_vector(C_DATA_WIDTH - 1 downto 0);
    signal stages        : stage_array;
    signal sticky_stages : std_logic_vector(0 to S);

begin
    -- Initial stage
    stages(0)        <= i_number;
    sticky_stages(0) <= '0';

    -- Logarithmic stages (Shift by 1, 2, 4, 8...)
    gen_stages : for i in 0 to S - 1 generate
        constant SHIFT_VAL : integer := 2 ** i;
    begin
        process(stages(i), i_shift_count(i), sticky_stages(i))
            --variable shifted_out_bits : std_logic_vector(shift_val-1 downto 0);
        begin
            if i_shift_count(i) = '1' then
                -- Standard Right Shift: fill with zeros
                stages(i + 1)                                        <= (others => '0');
                stages(i + 1)(C_DATA_WIDTH - 1 - SHIFT_VAL downto 0) <= stages(i)(C_DATA_WIDTH - 1 downto SHIFT_VAL);

                -- Sticky Logic: OR the bits being shifted out with the previous sticky bit
                --shifted_out_bits := stages(i)(shift_val-1 downto 0);
                sticky_stages(i + 1) <= sticky_stages(i) or or_reduce(stages(i)(SHIFT_VAL - 1 downto 0));
            else
                -- No shift in this stage
                stages(i + 1)        <= stages(i);
                sticky_stages(i + 1) <= sticky_stages(i);
            end if;
        end process;
    end generate;

    o_result(C_DATA_WIDTH downto 1) <= stages(S);
    o_result(0)                     <= sticky_stages(S);

end architecture;

-- Sticky Shifter that uses ARITHMETIC right shift
architecture arith_rtl of sticky_shifter is
    constant S : integer := integer(ceil(log2(real(C_DATA_WIDTH))));

    -- Functions to perform OR-reduction on a vector
    function or_reduce(v : std_logic_vector) return std_logic is
        variable res : std_logic := '0';
    begin
        for i in v'range loop
            res := res or v(i);
        end loop;
        return res;
    end function;

    type   stage_array   is array (0 to S) of std_logic_vector(C_DATA_WIDTH - 1 downto 0);
    signal stages        : stage_array;
    signal sticky_stages : std_logic_vector(0 to S);

begin
    -- Initial stage
    stages(0)        <= i_number;
    sticky_stages(0) <= '0';

    -- Logarithmic stages (Shift by 1, 2, 4, 8...)
    gen_stages : for i in 0 to S - 1 generate
        constant SHIFT_VAL : integer := 2 ** i;
    begin
        process(stages(i), i_shift_count(i), sticky_stages(i))
            --variable shifted_out_bits : std_logic_vector(shift_val-1 downto 0);

            -- Sign bit of the current stage (MSB)
            variable v_sign_bit : std_logic;
        begin
            v_sign_bit := stages(i)(C_DATA_WIDTH - 1); -- Capture sign bit

            if i_shift_count(i) = '1' then
                -- ARITHMETIC Right Shift: fill with sign_bit instead of '0'
                -- Fill the upper bits with the sign bit
                stages(i + 1)                                        <= (others => v_sign_bit);
                stages(i + 1)(C_DATA_WIDTH - 1 - SHIFT_VAL downto 0) <= stages(i)(C_DATA_WIDTH - 1 downto SHIFT_VAL);

                -- Sticky Logic: OR the bits being shifted out with the previous sticky bit
                --shifted_out_bits := stages(i)(shift_val-1 downto 0);
                sticky_stages(i + 1) <= sticky_stages(i) or or_reduce(stages(i)(SHIFT_VAL - 1 downto 0));
            else
                -- No shift in this stage
                stages(i + 1)        <= stages(i);
                sticky_stages(i + 1) <= sticky_stages(i);
            end if;
        end process;
    end generate;

    o_result(C_DATA_WIDTH downto 1) <= stages(S);
    o_result(0)                     <= sticky_stages(S);

end architecture;