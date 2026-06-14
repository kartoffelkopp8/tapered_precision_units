library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity formal_wrapper_log_decoder is
    port(
        clk : in std_logic;
        rst : in std_logic
    );
end entity formal_wrapper_log_decoder;

architecture Test of formal_wrapper_log_decoder is
    constant G_N           : integer := 32;
    constant C_FRACT_WIDTH : integer := G_N - 3;

    signal uut_takum : std_logic_vector(G_N - 1 downto 0);
    signal uut_l     : std_logic_vector(G_N + 3 downto 0);

    signal gold_l : std_logic_vector(G_N + 3 downto 0);

    signal is_special_case : std_logic;
begin
    dut : entity work.takum_logarithmic_decoder
        generic map(
            G_N => G_N
        )
        port map(
            i_takum => uut_takum,
            o_l     => uut_l
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

    gold_mant := (others => '0');
    for i in 0 to (G_N - 5 - 1) loop
        if (G_N - 6 - reg - i) >= 0 then
            gold_mant(G_N - 5 - 1 - i) := uut_takum(G_N - 6 - reg - i);
        end if;
    end loop;

    if sign = '0' then
        gold_l <= std_logic_vector(to_signed(char, 9)) & gold_mant;
    else
        -- Für die Invertierung wandeln wir das gesamte Paket erst in ein 'signed',
        -- negieren es mit dem unären minus '-' und casten es zurück in den std_logic_vector
        gold_l <= std_logic_vector(-signed(std_logic_vector(to_signed(char, 9)) & gold_mant));
    end if;
    end process reference;

    -- verification
    -- psl default clock is rising_edge(clk);

    -- psl assume always is_special_case = '0';
    -- psl assert always (uut_l = gold_l);

end architecture Test;
