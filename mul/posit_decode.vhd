library work;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity posit_decode is

    generic(
        N  : integer := 8;
        Bs : integer := 3;              -- log2(N)
        es : integer := 4
    );
    port(
        in_val : in  std_logic_vector(N - 1 downto 0);
        rc     : out std_logic;
        regime : out std_logic_vector(Bs - 1 downto 0);
        exp    : out std_logic_vector(es - 1 downto 0);
        mant   : out std_logic_vector(N - es - 3 downto 0)
    );
end posit_decode;

architecture Behavioral of posit_decode is

    signal rc_tmp : std_logic;
    signal xin    : std_logic_vector(N - 1 downto 0);

    signal xin_r     : std_logic_vector(N - 1 downto 0);
    signal lod_input : std_logic_vector(N - 1 downto 0);
    signal k_tmp     : std_logic_vector(Bs - 1 downto 0);
    signal k         : std_logic_vector(Bs - 1 downto 0);
    signal k_vld     : std_logic;

    signal xin_tmp : std_logic_vector(N - 3 downto 0);

begin

    -- 2's complement conversion already in posit_adder
    xin <= in_val;

    -- The Bit after the Sign of XINs depicts the sign of regime value and acts as Regime Check (RC) bit
    rc_tmp <= xin(N - 1);

    -- Invert if regime has positive value so only one LOD is necessary
    xin_r <= (not xin) when rc_tmp = '1' else xin;

    -- RC determines either of K0 orK1 as R[RS-1:0] (absolute regime value) and regime left shift amount (Lshift) of respective operands.
    lod_input <= xin_r(N - 1 downto 0); -- & (rc_tmp xor '0');

    LOD : entity work.LOD_T
        generic map(
            G_DATA_WIDTH => N
        )
        port map(
            i_x   => lod_input,
            o_K   => k_tmp,
            o_vld => k_vld
        );

    -- Check if LOD has a valid result. Otherwise set k to maximum value
    k <= (others => '1') when k_vld = '0' else k_tmp;
    --k <= k_tmp;

    -- Reduce k by 1 if Regime is positive to comply with standard
    regime <= std_logic_vector(unsigned(k) - 1) when rc_tmp = '1' else k;

    -- To extract the exponent and mantissa, the respective XIN is dynamically left shifted by k to push-out the entire regime
    -- bits and align exponent and mantissa at MSB. Now the MSB ES bit will act as the exponent and remaining bit would be mantissa bits.
    -- The "00" is used to remove the sign bit and the regime end bit independendly of the value of k
    xin_tmp <= std_logic_vector(shift_left(unsigned(xin(N - 3 downto 0)), to_integer(unsigned(k) - 1)));

    exp  <= xin_tmp(N - 3 downto N - 2 - es);
    mant <= xin_tmp(N - es - 3 downto 0);
    rc   <= rc_tmp;

end Behavioral;
