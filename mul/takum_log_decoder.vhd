library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity takum_log_decoder is
    generic(
        G_N : integer := 32
    );
    port(
        i_vec : in  std_logic_vector(G_N - 1 downto 0);
        o_l   : out std_logic_vector(G_N - 5 downto 0)
    );
end entity takum_log_decoder;

architecture Behavioral of takum_log_decoder is
    signal s_sign   : std_logic;
    signal s_dir    : std_logic;
    signal s_regime : std_logic_vector(2 downto 0); -- value by which we have to shift
    signal s_c_bias : std_logic_vector(6 downto 0); -- bias of characteristics bit

    signal s_cm            : std_logic_vector(G_N - 5 - 1 downto 0); -- extracted vector witrh only characteristics and regiem
    -- TODO for end result we habe to add the mask to c and then +1 bit
    signal s_shifter_input : std_logic_vector(G_N - 5 + 3 - 1 downto 0); -- G_N-5 is c+m bits, and then we have as a result 7 bits in front of the comma, and m after. worst case we need to shift by 7 to align

    signal s_mask_align_tmp : std_logic_vector(6 downto 0); -- maximum size of c is 7 bits
    signal s_mask_align     : std_logic_vector(s_cm'range); -- maximum size of c is 7 bits

    signal s_cm_with_mask : std_logic_vector(G_N - 5 downto 0);
    signal s_cm_inverted  : std_logic_vector(G_N - 5 downto 0);

begin
    s_sign   <= i_vec(G_N - 1);
    s_dir    <= i_vec(G_N - 2);
    s_regime <= i_vec(G_N - 3 downto G_N - 5) when s_dir = '1' else not (i_vec(G_N - 3 downto G_N - 5));
    s_cm     <= i_vec(G_N - 5 - 1 downto 0);

    -- TODO thinbk about if we can reuse maybe a bit of this for main shifter?
    mask_generator : entity work.takum_shift_right
        generic map(
            G_N         => 7,
            G_MAX_SHIFT => 3
        )
        port map(
            i_vec          => (others => '0'),
            i_fill_bit     => s_dir,
            i_shift_amount => s_regime,
            o_vec          => s_mask_align_tmp
        );

    s_mask_align <= (s_mask_align_tmp(6 downto 1) & '0' & (s_mask_align'high - 7 downto 0 => '0')) when (s_dir = '1' and s_regime = "000") else
                    (s_mask_align_tmp(6 downto 1) & '1' & (s_mask_align'high - 7 downto 0 => '0'));

    s_cm_with_mask <= std_logic_vector(unsigned('0' & s_mask_align) + unsigned('0' & s_cm));
    s_cm_inverted  <= s_cm_with_mask when s_sign = '0' else std_logic_vector(unsigned(not (s_cm_with_mask)) + 1); -- use twos complment for calculating l according to standard, sign should not be needed, because result sign will be calculated using sign1 xor sign 2

    o_l <= s_cm_inverted;
end architecture Behavioral;
