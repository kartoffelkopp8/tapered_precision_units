library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity takum_shift_left is
    generic(
        G_N         : integer := 32;          -- Breite des Vektors
        G_MAX_SHIFT : integer := 3            -- max. Shift (2^G_MAX_SHIFT - 1)
    );
    port(
        i_vec          : in  std_logic_vector(G_N-1 downto 0);
        i_fill_bit     : in  std_logic;       -- Bit zum Auffüllen (rechts)
        i_shift_amount : in  std_logic_vector(G_MAX_SHIFT-1 downto 0);
        o_vec          : out std_logic_vector(G_N-1 downto 0)
    );
end entity takum_shift_left;

architecture open_rtl of takum_shift_left is
    type stage_array is array (0 to G_MAX_SHIFT) of std_logic_vector(G_N-1 downto 0);
    signal stages : stage_array;

begin
    stages(0) <= i_vec;

    gen_stages : for i in 0 to G_MAX_SHIFT-1 generate
        constant SHIFT_VAL : integer := 2**i;
    begin
        process(stages(i), i_shift_amount(i), i_fill_bit)
        begin
            if i_shift_amount(i) = '1' then
                -- Left Shift: Bits wandern nach links, rechts wird aufgefüllt
                stages(i+1) <= (others => i_fill_bit);
                stages(i+1)(G_N-1 downto SHIFT_VAL) <= stages(i)(G_N-1 - SHIFT_VAL downto 0);
            else
                stages(i+1) <= stages(i);
            end if;
        end process;
    end generate;

    o_vec <= stages(G_MAX_SHIFT);

end architecture open_rtl;