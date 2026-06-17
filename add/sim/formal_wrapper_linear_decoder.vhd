library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity formal_wrapper_linear_decoder is
    port(
        clk : in std_logic;
        rst : in std_logic
    );
end entity formal_wrapper_linear_decoder;

architecture Test of formal_wrapper_linear_decoder is
    constant G_N           : integer := 32;
    constant C_FRACT_WIDTH : integer := G_N - 3;

    signal uut_takum : std_logic_vector(G_N - 1 downto 0);
    signal uut_exp   : std_logic_vector(8 downto 0);
    signal uut_fract : std_logic_vector(C_FRACT_WIDTH - 1 downto 0);

    signal gold_exp   : std_logic_vector(8 downto 0);
    signal gold_fract : std_logic_vector(C_FRACT_WIDTH - 1 downto 0);

    signal is_special_case : std_logic;
begin
    dut : entity work.takum_linear_decoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum    => uut_takum,
            o_exponent => uut_exp,
            o_fraction => uut_fract
        );

    is_special_case <= '1' when uut_takum(G_N - 2 downto 0) = std_logic_vector'(G_N - 2 downto 0 => '0') else '0';
    -- golden reference 
    reference : process(uut_takum) is
        variable sign      : std_logic;
        variable dir       : std_logic;
        variable reg_bits  : std_logic_vector(2 downto 0);
        variable reg       : integer range 0 to 7;
        variable char_bits : std_logic_vector(6 downto 0);
        variable char      : integer;
        variable exp       : integer range -255 to 254;
        variable gold_mant : std_logic_vector(G_N - 5 - 1 downto 0);
    begin
        sign     := uut_takum(G_N - 1);
        dir      := uut_takum(G_N - 2);
        reg_bits := uut_takum(G_N - 3 downto G_N - 5);

        if dir = '0' then
            reg := (7 - to_integer(unsigned(reg_bits)));
        else
            reg := to_integer(unsigned(reg_bits));
        end if;

        char_bits := (others => '0');
        for i in 0 to 6 loop
            if i < reg then
                if (G_N - 6 - i) >= 0 then
                    char_bits(i) := uut_takum(G_N - 6 - i);
                end if;
            end if;
        end loop;

        if dir = '0' then
            char := (-(2 ** reg + 1) + 1) + to_integer(unsigned(char_bits));
        else
            char := ((2 ** reg) - 1) + to_integer(unsigned(char_bits));
        end if;

        if sign = '0' then
            exp := char;
        else
            exp := -(char + 1);
        end if;

        gold_exp <= std_logic_vector(to_signed(exp, gold_exp'length));

        gold_mant := (others => '0');
        for i in 0 to (G_N - 5 - 1) loop
            if (G_N - 6 - reg - i) >= 0 then
                gold_mant(G_N - 5 - 1 - i) := uut_takum(G_N - 6 - reg - i);
            end if;
        end loop;

        if sign = '1' then
            gold_fract <= "10" & gold_mant;
        else
            gold_fract <= "01" & gold_mant;
        end if;
    end process reference;

    -- verification
    -- psl default clock is rising_edge(clk);

    -- psl assume always is_special_case = '0';
    -- psl assert always (uut_exp = gold_exp);
    --psl assert always (uut_fract = gold_fract);

end architecture Test;
