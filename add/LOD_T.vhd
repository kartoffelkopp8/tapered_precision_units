library ieee;
library work;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.pkg_utility.all;

entity LOD_T is
	generic(
		G_DATA_WIDTH : integer := 62	--posit width without sign
	);
	port(
		i_x   : in  std_logic_vector(G_DATA_WIDTH - 1 downto 0); -- input 
		o_K   : out std_logic_vector(integer(clog2(G_DATA_WIDTH)) - 1 downto 0);
		o_vld : out std_logic           -- valid bit
	);
end entity;

architecture behav of LOD_T is
	constant C_NEXT_POW2 : integer := 2 ** integer(clog2(G_DATA_WIDTH));
	constant C_IS_POW2   : boolean := (C_NEXT_POW2 = G_DATA_WIDTH);	
	signal s_K   : std_logic_vector(integer(clog2(G_DATA_WIDTH)) - 1 downto 0);
	signal s_vld : std_logic;

	-- signals for the non power of two recursion case
	signal s_x_tmp : std_logic_vector((2 ** integer(clog2(G_DATA_WIDTH))) - 1 downto 0);

	-- signals for the power of two recursion case
	signal s_K_L   : std_logic_vector(integer(clog2(G_DATA_WIDTH)) - 2 downto 0);
	signal s_K_H   : std_logic_vector(integer(clog2(G_DATA_WIDTH)) - 2 downto 0);
	signal s_vld_L : std_logic;
	signal s_vld_H : std_logic;

begin

	o_K   <= s_K;
	o_vld <= s_vld;

	recursive_gen_width_2 : if G_DATA_WIDTH = 2 generate

		s_vld <= or_reduce(i_x);
		s_K   <= (0 => ((not i_x(1)) and i_x(0)));
	end generate recursive_gen_width_2;

	-- round up to nearest power of two
	recursive_gen_width_odd : if C_IS_POW2 = False generate

		s_x_tmp <= i_x & ((2 ** integer(clog2(G_DATA_WIDTH))) - G_DATA_WIDTH - 1 downto 0 => '0');

		inst_LOD : entity work.LOD_T
			generic map(
				G_DATA_WIDTH => (2 ** integer(clog2(G_DATA_WIDTH)))
			)
			port map(
				i_x   => s_x_tmp,
				o_K   => s_K,
				o_vld => s_vld
			);
	end generate recursive_gen_width_odd;


	recursive_gen_width_even : if G_DATA_WIDTH > 2 and C_IS_POW2 = TRUE generate

		inst_LOD_low : entity work.LOD_T
			generic map(
				G_DATA_WIDTH => (G_DATA_WIDTH / 2)
			)
			port map(
				i_x   => i_x((G_DATA_WIDTH / 2) - 1 downto 0),
				o_K   => s_K_L,
				o_vld => s_vld_L
			);

		inst_LOD_high : entity work.LOD_T
			generic map(
				G_DATA_WIDTH => (G_DATA_WIDTH / 2)
			)
			port map(
				i_x   => i_x(G_DATA_WIDTH - 1 downto G_DATA_WIDTH / 2),
				o_K   => s_K_H,
				o_vld => s_vld_H
			);

		s_vld <= s_vld_L or s_vld_H;
		-- if high valid => ignore rest and prepend 0 for next larger result 
		-- else: append valid low to K low because upper half is all 0
		s_K   <= ('0' & s_K_H) when s_vld_H = '1' else (s_vld_L & s_K_L);

	end generate recursive_gen_width_even;

end architecture;