library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SUBX is

	generic
	(
		size : natural := 16
	);

	port 
	(
		A		: in  std_logic_vector(size-1 downto 0);
		B		: in std_logic_vector(size-1 downto 0);
		Cin	: in std_logic;
		F		: out std_logic_vector(size-1 downto 0);
		Cout	: out std_logic
	);

end entity;

architecture rtl of SUBX is
begin

	process(A,B,cin) is 
		variable ta,tb,tf:std_logic_vector(size downto 0);
	begin 
		ta(size)					:=A(size-1);
		ta(size-1 downto 0)	:=A(size-1 downto 0);
		tb(size)					:=B(size-1);
		tb(size-1 downto 0)	:=B(size-1 downto 0);
		
		if Cin='0' then
			tf:= std_logic_vector(to_unsigned(to_integer(unsigned(ta))-to_integer(unsigned(tb)),size+1));
			F(size-1 downto 0)	<=tf(size-1 downto 0);
			Cout						<=tf(size);
		else
			tf:= std_logic_vector(to_unsigned(to_integer(unsigned(ta))-to_integer(unsigned(tb))-1,size+1));
			F(size-1 downto 0)	<=tf(size-1 downto 0);
			Cout						<=tf(size);
		end if;
		
	end process; 
end rtl;
