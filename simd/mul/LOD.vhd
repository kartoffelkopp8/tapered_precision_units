library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.utility_pkg.all;

entity LOD is
	generic (
		G_DATA_WIDTH : integer := 8
	);
	port (
		i_x : in std_logic_vector(G_DATA_WIDTH-1 downto 0);
		o_K : out std_logic_vector(clog2(G_DATA_WIDTH)-1 downto 0);
		o_vld : out std_logic
	);
end entity;

architecture behav of LOD is

function is_power_of_two(i: integer) return boolean is
    variable temp : integer := i;
begin
    if i <= 0 then return false; end if;
    if i = 1 then return true;  end if; -- 2^0 ist 1
    
    -- Solange durch 2 teilbar, teile durch 2
    while (temp > 1) loop
        if (temp mod 2 /= 0) then
            return false;
        end if;
        temp := temp / 2;
    end loop;
    return true;
end function;


	function or_reduce(V: std_logic_vector)
	return std_logic is
		variable result: std_logic := '0';
	begin
		for i in V'range loop
			result := result or V(i);
		end loop;
		return result;
	end or_reduce;
	
	signal s_K : std_logic_vector(integer(ceil(log2(real(G_DATA_WIDTH))))-1 downto 0);
	signal s_vld : std_logic;
	
	-- signals for the non power of two recursion case
	signal s_x_tmp : std_logic_vector((2**integer(ceil(log2(real(G_DATA_WIDTH)))))-1 downto 0);
	
	-- signals for the power of two recursion case
	signal s_K_L : std_logic_vector(integer(ceil(log2(real(G_DATA_WIDTH))))-2 downto 0);
	signal s_K_H : std_logic_vector(integer(ceil(log2(real(G_DATA_WIDTH))))-2 downto 0);
	signal s_vld_L : std_logic;
	signal s_vld_H : std_logic;

begin

	o_K <= s_K;
	o_vld <= s_vld;

	recursive_gen_width_2: if G_DATA_WIDTH = 2 generate
		
		s_vld <= or_reduce(i_x);
		s_K <= (0 => ((not i_x(1)) and i_x(0)));
	end generate recursive_gen_width_2;

	recursive_gen_width_odd: if is_power_of_two(G_DATA_WIDTH) = False generate
	
		s_x_tmp <= i_x & ((2**integer(ceil(log2(real(G_DATA_WIDTH)))))-G_DATA_WIDTH-1 downto 0 => '0');		
	
		inst_LOD: entity work.LOD
		generic map (
			G_DATA_WIDTH => (2**integer(ceil(log2(real(G_DATA_WIDTH)))))
		)
		port map (
			i_x => s_x_tmp,
			o_K => s_K,
			o_vld => s_vld
		);
	end generate recursive_gen_width_odd;

	recursive_gen_width_even: if G_DATA_WIDTH > 2 and is_power_of_two(G_DATA_WIDTH) = TRUE generate

		inst_LOD_low: entity work.LOD
		generic map (
			G_DATA_WIDTH => (G_DATA_WIDTH/2)
		)
		port map (
			i_x => i_x((G_DATA_WIDTH/2)-1 downto 0),
			o_K => s_K_L,
			o_vld => s_vld_L
		);
		
		
		inst_LOD_high: entity work.LOD
		generic map (
			G_DATA_WIDTH => (G_DATA_WIDTH/2)
		)
		port map (
			i_x => i_x(G_DATA_WIDTH-1 downto G_DATA_WIDTH/2),
			o_K => s_K_H,
			o_vld => s_vld_H
		);
		
		s_vld <= s_vld_L or s_vld_H;
		s_K <= ("0" & s_K_H) when s_vld_H = '1' else ((0 => s_vld_L) & s_K_L);
	
	end generate recursive_gen_width_even;
	

end architecture;
