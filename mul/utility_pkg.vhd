library ieee;
use ieee.std_logic_1164.all;

package utility_pkg is
    function or_reduce(vec : std_logic_vector) return std_logic;
end package utility_pkg;

package body utility_pkg is
    function or_reduce(vec: std_logic_vector)
	return std_logic is
		variable result: std_logic := '0';
	begin
		for i in vec'range loop
			result := result or vec(i);
		end loop;
		return result;
	end or_reduce;

    
end package body utility_pkg;
