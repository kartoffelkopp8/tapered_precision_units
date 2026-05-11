library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity takum_logarithmic_decoder is
    generic(
        G_N : integer := 32
    );
    port(
        i_takum : in  std_logic_vector(G_N - 1 downto 0);
        o_c     : out std_logic_vector(8 downto 0); -- TODO evaluate if sign bit is really needed, we can calculate result sign, and is aleready twos comp
        o_mant  : out std_logic_vector(G_N - 5 - 1 downto 0)
    );
end entity takum_logarithmic_decoder;

architecture Behavioral of takum_logarithmic_decoder is
    signal s_dir         : std_logic;
    signal s_regime      : std_logic_vector(2 downto 0);
    signal s_regime_raw  : std_logic_vector(2 downto 0);
    signal s_antiregime  : std_logic_vector(2 downto 0);
    signal s_char_raw    : std_logic_vector(6 downto 0);
    signal s_char_invert : std_logic_vector(6 downto 0);

    signal s_char_tmp : std_logic_vector(8 downto 0);
    signal s_char_post_shift : std_logic_vector(8 downto 0);
    signal s_char_post_inc : std_logic_vector(8 downto 0);
    signal s_char : std_logic_vector(8 downto 0);

    -- mantissa 
    signal s_mantissa : std_logic_vector(G_N-5-1 downto 0);
    signal s_mantissa_extracted : std_logic_vector(s_mantissa'range);
begin
    -- extract values from takum
    s_dir        <= i_takum(G_N - 2);
    s_regime_raw <= i_takum(G_N - 3 downto G_N - 5);
    s_char_raw   <= i_takum(G_N - 5 - 1 downto G_N - 12);

    s_mantissa <= i_takum(G_N-5-1 downto 0);

    gen_regime : for i in 0 to 2 generate
        s_regime(i) <= not(s_dir) xor s_regime_raw(i);
    end generate;
    s_antiregime <= not (s_regime);

    gen_inv_char_raw : for i in 0 to 6 generate
        s_char_invert(i) <= s_dir xor s_char_raw(i);
    end generate;

    s_char_tmp <= "10" & s_char_invert;

    char_shifter : entity work.takum_shift_right
        generic map(
            G_N         => 9,
            G_MAX_SHIFT => 3
        )
        port map(
            i_vec          => s_char_tmp,
            i_fill_bit     => '1',
            i_shift_amount => s_antiregime,
            o_vec          => s_char_post_shift
        );

    s_char_post_inc <= s_char_post_shift(s_char_post_shift'high) & std_logic_vector(unsigned(s_char_post_shift(7 downto 0)) + 1);
    

    invert : process(s_char_post_inc, s_dir) 
    begin 
        s_char(8) <= s_char_post_inc(8);
        for i in 0 to 7 loop 
            s_char(i) <= s_dir xor s_char_post_inc(i);
        end loop;
    end process;

    mant_shifter : entity work.takum_shift_left
        generic map(
            G_N         => G_N-5,
            G_MAX_SHIFT => 3
        )
        port map(
            i_vec          => s_mantissa,
            i_fill_bit     => '0',
            i_shift_amount => s_regime,
            o_vec          => s_mantissa_extracted
        );
    
    o_mant <= s_mantissa_extracted;
    o_c <= s_char;

end architecture Behavioral;
