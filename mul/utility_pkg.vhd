library ieee;
use ieee.std_logic_1164.all;

package utility_pkg is
	function or_reduce(vec : std_logic_vector) return std_logic;
	function cond_invert(vec : std_logic_vector; inv : std_logic) return std_logic_vector;
end package utility_pkg;

package body utility_pkg is
	function or_reduce(vec : std_logic_vector)
	return std_logic is
		variable result : std_logic := '0';
	begin
		for i in vec'range loop
			result := result or vec(i);
		end loop;
		return result;
	end or_reduce;

	function cond_invert(vec : std_logic_vector; inv : std_logic)
	return std_logic_vector is
		variable result : std_logic_vector(vec'range);
	begin
		for i in vec'range loop 
			result(i) := inv xor vec(i);
		end loop;
		return result;
	end function;
end package body utility_pkg;
