library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.pkg_utility.all;

--shifts i_number rigth by i_shift_count and fills from the rigth with i_shift_bit
entity sticky_shift_det is
    generic(
        C_DATA_WIDTH : integer := 26
    );
    port(
        i_number      : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0); -- number to be shifted
        i_shift_count : in  std_logic_vector(integer(ceil(log2(real(C_DATA_WIDTH)))) - 1 downto 0); -- ammount shifted
        i_shift_bit    : in std_logic; -- bit wich is shifted in from the rigth
        o_result      : out std_logic_vector(C_DATA_WIDTH downto 0) -- shifted result with lowest bit as cumulative sticky bit
    );
end entity;

architecture Tree of sticky_shift_det is
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
        process(stages(i), i_shift_count(i), sticky_stages(i), i_shift_bit)
            --variable shifted_out_bits : std_logic_vector(shift_val-1 downto 0);
        begin
            if i_shift_count(i) = '1' then
                -- Standard Right Shift: fill with zeros
                stages(i + 1)                                        <= (others => i_shift_bit);
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