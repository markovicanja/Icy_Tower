library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADDX is

	generic
	(
		size : natural := 16
	);

	port 
	(
		A		: in unsigned(size-1 downto 0);
		B		: in unsigned(size-1 downto 0);
		Cin	: in std_logic;
		F		: out unsigned(size-1 downto 0);
		Cout	: out std_logic
	);

end entity;

architecture rtl of ADDX is
begin

	process(A,B,cin) is 
		variable ta:unsigned(size downto 0);
	begin 
		ta := '0' & a + b;
		F <= ta(size-1 downto 0);
		Cout <= ta(size);
	end process;
end rtl;
