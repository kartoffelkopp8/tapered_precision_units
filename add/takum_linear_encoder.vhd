library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity takum_linear_encoder is
    generic(
        G_N : integer := 32
    );
    port(
        i_sign_bit : in  std_logic;
        i_overflow : in std_logic;
        i_underflow : in std_logic;
        i_fraction : in  std_logic_vector(G_N - 6 downto 0);
        i_exp      : in  std_logic_vector(8 downto 0);
        o_takum    : out std_logic_vector(G_N - 1 downto 0)
    );
end entity takum_linear_encoder;

architecture RTL of takum_linear_encoder is
    signal characteristic : std_logic_vector(8 downto 0);
begin
    characteristic <= not (i_exp) when i_sign_bit = '1' else i_exp;

    takum_logarithmic_encoder_inst : entity work.takum_logarithmic_encoder
        generic map(
            G_N => G_N
        )
        port map(
            i_sign      => i_sign_bit,
            i_l         => characteristic & i_fraction,
            i_overflow  => i_overflow,
            i_underflow => i_underflow,
            o_takum     => o_takum
        );

end architecture RTL;
