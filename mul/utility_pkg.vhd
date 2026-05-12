library ieee;
use ieee.std_logic_1164.all;

package utility_pkg is
	function or_reduce(vec : std_logic_vector) return std_logic;
	function cond_invert(vec : std_logic_vector; inv : std_logic) return std_logic_vector;
	function clog2(n : integer) return integer;
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

	  function clog2(n : integer) return integer is
        variable r : integer := 0;
        variable m : integer := 1;
    begin
        while m < n loop
            m := m * 2;
            r := r + 1;
        end loop;
        return r;
    end function;

end package body utility_pkg;
