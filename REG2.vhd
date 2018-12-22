-- REG2

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity REG2 is
	port (
		clk	: in std_logic;
		cl		: in std_logic;
		i		: in std_logic_vector(1 downto 0);
		ld		: in std_logic;
		cin 	: in std_logic;
		inc	: in std_logic;
		ein	: in std_logic;
		dec	: in std_logic;
		ir		: in std_logic;
		shr	: in std_logic;
		il		: in std_logic;
		shl	: in std_logic;
		
		cout	: out std_logic;
		eout	: out std_logic;
		q		: out std_logic_vector(1 downto 0)
	);
end entity;

architecture reg2 of REG2 is
	signal state		:	std_logic_vector(1 downto 0)	:=	('0', '0');
	signal coutVector	:	std_logic							:=	'0';
	signal eoutVector	: 	std_logic							:=	'0';
begin
	q <= state;
	
	reg10 : entity work.reg1 port map(
		--input signals
		clk	=> clk,
		cl 	=> cl,
		i 		=> i(0),
		ld		=> ld,
		cin 	=> cin,
		inc	=> inc,
		ein 	=> ein,
		dec 	=> dec,
		ir 	=> state(1),
		shr 	=> shr,
		il 	=> il,
		shl 	=> shl,
		
		--output signals
		cout 	=> coutVector,
		eout 	=> eoutVector,
		q 		=> state(0)
	);
	
	
	reg12 : entity work.reg1 port map(
		--input signals
		clk	=> clk,
		cl 	=> cl,
		i 		=> i(1),
		ld		=> ld,
		cin 	=> coutVector,
		inc	=> inc,
		ein 	=> eoutVector,
		dec 	=> dec,
		ir 	=> ir,
		shr 	=> shr,
		il 	=> state(0),
		shl 	=> shl,
		
		--output signals
		cout 	=> cout,
		eout 	=> eout,
		q 		=> state(1)
	);

end reg2;
